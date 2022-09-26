//
//  MetalDeviceCache.swift
//  ColorCorrector
//
//  Created by Joseph Slinker on 4/27/22.
//

import Foundation

let kMaxCommandQueues   = 5
let kKey_InUse          = "InUse"
let kKey_CommandQueue   = "CommandQueue"

class MetalDeviceCacheItem: NSObject {
    let gpuDevice : MTLDevice
    let pipelineState : MTLRenderPipelineState
    let pixelFormat : MTLPixelFormat
    var commandQueueCache : [Dictionary<String, Any>]
    var commandQueueCacheLock : NSLock
    
    init(with newDevice:MTLDevice, pixFormat:MTLPixelFormat) throws {
        gpuDevice = newDevice
        
        // Set up the command queue cache for each device
        commandQueueCache = Array.init()
        for _ in 0..<kMaxCommandQueues
        {
            var commandDict = Dictionary.init() as Dictionary<String, Any>
            commandDict[kKey_InUse] = false
            
            let commandQueue = gpuDevice.makeCommandQueue()
            commandDict[kKey_CommandQueue] = commandQueue
            
            commandQueueCache.append(commandDict)
        }
        
        // Load all the shader files with a .metal file extension in the project
        let defaultLibrary = gpuDevice.makeDefaultLibrary()
        
        // Configure a pipeline descriptor that is used to cerate a pipeline state
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor.init()
        pipelineStateDescriptor.label = "MetalBrightness"
        let vertexFunction = defaultLibrary?.makeFunction(name: "vertexShader")
        let fragmentFunction = defaultLibrary?.makeFunction(name: "fragmentShader")
        pipelineStateDescriptor.vertexFunction = vertexFunction
        pipelineStateDescriptor.fragmentFunction = fragmentFunction
        pipelineStateDescriptor.colorAttachments [0].pixelFormat = pixFormat
        pixelFormat = pixFormat

        try pipelineState = gpuDevice.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
        
        commandQueueCacheLock = NSLock.init()
    }
    
    func getNextFreeCommandQueue() -> MTLCommandQueue? {
        var result = nil as MTLCommandQueue?
        
        commandQueueCacheLock.lock()
        var index = 0;
        while ((result == nil) && index < kMaxCommandQueues)
        {
            var nextCommandQueue = commandQueueCache [ index ]
            let inUse = nextCommandQueue[kKey_InUse] as! Bool
            if !inUse
            {
                nextCommandQueue[kKey_InUse] = true
                result = nextCommandQueue[kKey_CommandQueue] as? MTLCommandQueue
            }
            index += 1
        }
        commandQueueCacheLock.unlock()
        
        return result
    }
    
    func returnCommandQueue(commandQueue:MTLCommandQueue) {
        commandQueueCacheLock.lock()
        
        var found = false
        var index = 0
        while ((!found) && (index < kMaxCommandQueues))
        {
            var nextCommandQueueDict    = commandQueueCache[index]
            let nextCommandQueue = nextCommandQueueDict [ kKey_CommandQueue ] as? MTLCommandQueue
            if (nextCommandQueue === commandQueue)
            {
                found = true
                nextCommandQueueDict [ kKey_InUse ] = false
            }
            index += 1;
        }
        
        commandQueueCacheLock.unlock()
    }
    
    func containsCommandQueue(commandQueue:MTLCommandQueue) -> Bool {
        var found = false
        
        commandQueueCacheLock.lock()
        
        var index   = 0
        while ((!found) && (index < kMaxCommandQueues))
        {
            let nextCommandQueueDict    = commandQueueCache [ index ];
            let nextCommandQueue        = nextCommandQueueDict [ kKey_CommandQueue ] as? MTLCommandQueue
            if (nextCommandQueue === commandQueue)
            {
                found = true
            }
            index += 1
        }
        
        commandQueueCacheLock.unlock()
        
        return found;
    }
}

class MetalDeviceCache: NSObject {
    var deviceCaches : [MetalDeviceCacheItem]
    static let deviceCache = MetalDeviceCache()
        
    override init() {
        let devices = MTLCopyAllDevices()
        
        deviceCaches = Array.init()
        for nextDevice in devices
        {
            do {
                let newCacheItem = try MetalDeviceCacheItem.init(with: nextDevice, pixFormat: MTLPixelFormat.rgba16Float)
                deviceCaches.append(newCacheItem)
            } catch {
                NSLog ("Unable to create device cache in ColorCorrector.")
            }
        }
    }
    
    class func FxMTLPixelFormat(for imageTile:FxImageTile) -> MTLPixelFormat {
        var result = MTLPixelFormat.rgba16Float
        
        switch imageTile.ioSurface.pixelFormat {
        case kCVPixelFormatType_128RGBAFloat:
            result = MTLPixelFormat.rgba32Float
            
        case kCVPixelFormatType_32BGRA:
            result = MTLPixelFormat.bgra8Unorm
            
        default:
            NSLog("Got an unexpected pixel format in the IOSurface: 0x%08x", imageTile.ioSurface.pixelFormat)
        }
        return result
    }
    

    func device(with registryID:UInt64) -> MTLDevice? {
        for nextCacheItem in deviceCaches
        {
            if (nextCacheItem.gpuDevice.registryID == registryID)
            {
                return nextCacheItem.gpuDevice
            }
        }
        
        return nil
    }
    
    func pipelineState(with registryID:UInt64, pixelFormat:MTLPixelFormat) -> MTLRenderPipelineState? {
        for nextCacheItem in deviceCaches
        {
            if ((nextCacheItem.gpuDevice.registryID == registryID) &&
                (nextCacheItem.pixelFormat == pixelFormat))
            {
                return nextCacheItem.pipelineState
            }
        }
        
        // We didn't get one, so create a new one
        let devices = MTLCopyAllDevices()
        var device : MTLDevice?
        for nextDevice:MTLDevice in devices {
            if (nextDevice.registryID == registryID) {
                device = nextDevice
            }
        }
        
        var result:MTLRenderPipelineState?  = nil;
        if (device != nil) {
            do {
                let newCacheItem = try MetalDeviceCacheItem.init(with: device!, pixFormat: pixelFormat)
                deviceCaches.append(newCacheItem)
                result = newCacheItem.pipelineState
            } catch {
                NSLog ("Unable to create a new cache item with the desired pixel format")
            }
        }
        
        return result
    }
    
    func commandQueue(with registryID:UInt64, pixelFormat:MTLPixelFormat) -> MTLCommandQueue? {
        for nextCacheItem in deviceCaches
        {
            if ((nextCacheItem.gpuDevice.registryID == registryID) &&
                (nextCacheItem.pixelFormat == pixelFormat))
            {
                return nextCacheItem.getNextFreeCommandQueue()
            }
        }
        
        // We didn't get one, so create a new one
        let devices = MTLCopyAllDevices()
        var device : MTLDevice?
        for nextDevice:MTLDevice in devices {
            if (nextDevice.registryID == registryID) {
                device = nextDevice
            }
        }
        
        var result:MTLCommandQueue?  = nil;
        if (device != nil) {
            do {
                let newCacheItem = try MetalDeviceCacheItem.init(with: device!, pixFormat: pixelFormat)
                deviceCaches.append(newCacheItem)
                result = newCacheItem.getNextFreeCommandQueue()
            } catch {
                NSLog ("Unable to create a new cache item with the desired pixel format")
            }
        }
        
        return result
    }
    
    func returnCommandQueueToCache(commandQueue:MTLCommandQueue) {
        for nextCacheItem in deviceCaches
        {
            if nextCacheItem.containsCommandQueue(commandQueue: commandQueue)
            {
                nextCacheItem.returnCommandQueue(commandQueue: commandQueue)
                return
            }
        }
    }
}
