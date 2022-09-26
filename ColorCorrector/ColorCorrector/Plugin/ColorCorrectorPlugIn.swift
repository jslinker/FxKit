//
//  ColorCorrectorPlugIn.swift
//  ColorCorrector
//
//  Created by Joseph Slinker on 4/27/22.
//

import AVFoundation

enum ParameterID: UInt32 {
    case HueSaturation = 1
    case Value
    case WindowButton
}

let NoCommandQueueError: FxError = kFxError_ThirdPartyDeveloperStart + 1000

@objc(ColorCorrectorPlugIn) class ColorCorrectorPlugIn : NSObject, FxTileableEffect {
    
    static let CCPNoCommandQueueError: FxError = kFxError_ThirdPartyDeveloperStart + 1000
    
    private let _apiManager : PROAPIAccessing!
    
    private var customView: NSView? = nil
    
    required init?(apiManager: PROAPIAccessing) {
        _apiManager = apiManager
    }
    
    deinit {
        
    }
    
    // MARK: FxTileableEffect Protocol
    
    // Called whenever a new instance of the plugin is added to a users document. The original sample project used the `dispatch_once` pattern to initialize `gInstanceList` here. In Swift this is unnecessary because static variables are already lazily initialized.
    func pluginInstanceAddedToDocument() {
        
    }
    
    // Describes what the plugin is capable of. This value is cached in Motion and Final Cut Pro.
    func properties(_ properties: AutoreleasingUnsafeMutablePointer<NSDictionary>?) throws {
        let swiftProps = [
            kFxPropertyKey_MayRemapTime: NSNumber(booleanLiteral: false),
            kFxPropertyKey_PixelTransformSupport: NSNumber(integerLiteral: kFxPixelTransform_Full),
            kFxPropertyKey_ChangesOutputSize: NSNumber(booleanLiteral: false)
        ]
        
        let props = NSDictionary(dictionary: swiftProps)
        properties?.pointee = props
    }
    
    func addParameters() throws {
        let paramAPI = _apiManager!.api(for: FxParameterCreationAPI_v5.self) as! FxParameterCreationAPI_v5
        
        let bundle = Bundle(for: Self.self)
        let hueSatName = bundle.localizedString(forKey: "ColorCorrector::HueSaturation", value: nil, table: nil)
        let defaultColor = HueSaturation(hue: 30.0 * Double.pi / 180, saturation: 0.5)
        
        paramAPI.addCustomParameter(withName: hueSatName, parameterID: ParameterID.HueSaturation.rawValue,
                                    defaultValue: defaultColor,
                                    parameterFlags: .CustomUI | .DontDisplayInDashboard)
        
        paramAPI.addFloatSlider(withName: "Color Value", parameterID: ParameterID.Value.rawValue, defaultValue: 1.0, parameterMin: 0.0, parameterMax: 100.0, sliderMin: 0.0, sliderMax: 5.0, delta: 0.1, parameterFlags: .Default)
        
        paramAPI.addPushButton(withName: "Show Window", parameterID: ParameterID.WindowButton.rawValue, selector: #selector(showWindow), parameterFlags: .Default)
    }
    
    func pluginState(_ pluginState: AutoreleasingUnsafeMutablePointer<NSData>?, at renderTime: CMTime, quality qualityLevel: UInt) throws {
        let hsv = HueSaturation.fromAPI(self._apiManager, forParameter: 1, at: renderTime)
        var value: Double = 0.0
        self._apiManager.parameterRetrievalAPIV6()?.getFloatValue(&value, fromParameter: ParameterID.Value.rawValue, at: renderTime)
        let newState = NSMutableData()
        var hue = hsv.hue
        var sat = hsv.saturation
        newState.append(&hue, length: MemoryLayout.size(ofValue: hue))
        newState.append(&sat, length: MemoryLayout.size(ofValue: sat))
        newState.append(&value, length: MemoryLayout.size(ofValue: value))
        print("Plugin state out", hue, sat)
        pluginState?.pointee = newState
    }
    
    func destinationImageRect(_ destinationImageRect: UnsafeMutablePointer<FxRect>, sourceImages: [FxImageTile], destinationImage: FxImageTile, pluginState: Data?, at renderTime: CMTime) throws {
        destinationImageRect.pointee = sourceImages[0].imagePixelBounds
    }
    
    func sourceTileRect(_ sourceTileRect: UnsafeMutablePointer<FxRect>, sourceImageIndex: UInt, sourceImages: [FxImageTile], destinationTileRect: FxRect, destinationImage: FxImageTile, pluginState: Data?, at renderTime: CMTime) throws {
        sourceTileRect.pointee = destinationTileRect;
    }
    
    func renderDestinationImage(_ destinationImage: FxImageTile, sourceImages: [FxImageTile], pluginState: Data?, at renderTime: CMTime) throws {
        let deviceRegistryID = destinationImage.deviceRegistryID
        let deviceCache = MetalDeviceCache.deviceCache
        let pixelFormat = MetalDeviceCache.FxMTLPixelFormat(for: destinationImage)
        guard let commandQueue = deviceCache.commandQueue(with: deviceRegistryID, pixelFormat: pixelFormat) else {
            throw NSError(domain: FxPlugErrorDomain, code: NoCommandQueueError, userInfo: [NSLocalizedDescriptionKey: "Unable to get command queue in render. May need to increase cache size"])
        }

        // The documentation indicates that this function always returns a value and will block the thread until it has a command buffer
        let commandBuffer = commandQueue.makeCommandBuffer()!
        commandBuffer.label = "ColorCorrector Command Buffer"
        commandBuffer.enqueue()
        
        let inputTexture = destinationImage.metalTexture(for: deviceCache.device(with: sourceImages[0].deviceRegistryID))
        let outputTexture = destinationImage.metalTexture(for: deviceCache.device(with: destinationImage.deviceRegistryID))
        
        let colorAttachmentDescriptor = MTLRenderPassColorAttachmentDescriptor.init()
        colorAttachmentDescriptor.texture = outputTexture
        colorAttachmentDescriptor.clearColor = MTLClearColorMake(0.5, 0.0, 1.0, 1.0)
        colorAttachmentDescriptor.loadAction = MTLLoadAction.clear
        
        let renderPassDescriptor = MTLRenderPassDescriptor.init()
        renderPassDescriptor.colorAttachments[0] = colorAttachmentDescriptor
        
        // The documentation indicates this only fails if called twice before ending encoding
        let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        
        let pipelineState = deviceCache.pipelineState(with: deviceRegistryID, pixelFormat: pixelFormat)
        commandEncoder.setRenderPipelineState(pipelineState!)
        
        // Do rendering
        let hsv = HueSaturation.fromPluginState(pluginState!)
        var value: Double = 0.0
        let valueRange: NSRange = NSMakeRange(MemoryLayout.size(ofValue: hsv.hue) + MemoryLayout.size(ofValue: hsv.saturation), MemoryLayout.size(ofValue: value))
        (pluginState! as NSData).getBytes(&value, range: valueRange)
        
        var red: Double = 0
        var green: Double = 0
        var blue: Double = 0
        HSVToRGB(hue: hsv.hue, saturation: hsv.saturation, value: value, red: &red, green: &green, blue: &blue)
        
        let outputWidth = destinationImage.tilePixelBounds.right - destinationImage.tilePixelBounds.left
        let outputHeight = destinationImage.tilePixelBounds.top - destinationImage.tilePixelBounds.bottom
        var vertices = [
            Vertex2D(position: vector_float2(Float(outputWidth) / 2.0, Float(-outputHeight) / 2.0), textureCoordinate: vector_float2(1.0, 1.0)),
            Vertex2D(position: vector_float2(Float(-outputWidth) / 2.0, Float(-outputHeight) / 2.0), textureCoordinate: vector_float2(0.0, 1.0)),
            Vertex2D(position: vector_float2(Float(outputWidth) / 2.0, Float(outputHeight) / 2.0), textureCoordinate: vector_float2(1.0, 0.0)),
            Vertex2D(position: vector_float2(Float(-outputWidth) / 2.0, Float(outputHeight) / 2.0), textureCoordinate: vector_float2(0.0, 0.0))
        ]
        
        let ioSurfaceHeight = destinationImage.ioSurface.height
        let viewport = MTLViewport(originX: 0,
                                   originY: Double(ioSurfaceHeight - Int(outputHeight)),
                                   width: Double(outputWidth),
                                   height: Double(outputHeight),
                                   znear: -1.0,
                                   zfar: 1.0)
        commandEncoder.setViewport(viewport)
        
        commandEncoder.setVertexBytes(&vertices, length: MemoryLayout<Vertex2D>.size * 4, index: Int(SCC_Vertices.rawValue))
        
        var viewportSize = simd_uint2(UInt32(outputWidth), UInt32(outputHeight))
        commandEncoder.setVertexBytes(&viewportSize, length: MemoryLayout.size(ofValue: viewportSize), index: Int(SCC_ViewportSize.rawValue))
        
        commandEncoder.setFragmentTexture(inputTexture, index: Int(SCC_InputImage.rawValue))
        
        var color = vector_float4(Float(red), Float(green), Float(blue), 1)
        commandEncoder.setFragmentBytes(&color, length: MemoryLayout.size(ofValue: color), index: Int(SCC_Color.rawValue))
        
        commandEncoder.drawPrimitives(type: MTLPrimitiveType.triangleStrip, vertexStart: 0, vertexCount: 4)
        
        // Clean up
        commandEncoder.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        
        deviceCache.returnCommandQueueToCache(commandQueue: commandQueue)
    }
    
    @objc func showWindow() {
        guard let windowAPI = _apiManager.api(for: FxRemoteWindowAPI_v2.self) as? FxRemoteWindowAPI_v2 else {
            print("Unable to get windowing API")
            return
        }
        
        let contentSize = ColorCorrectorView.hueSaturationWheel.size
        windowAPI.remoteWindow(of: contentSize) { view, error in
            guard let parentView = view else {
                print("Error creating new remote window \(String(describing: error))")
                return
            }
            let wheelView = ColorCorrectorView(frame: NSRect(x: 0, y: 0, width: 200, height: 200), apiManager: self._apiManager)
            parentView.addSubview(wheelView)
        }
    }
    
    // Who knows if this function name is correct. The @objc was essential to making this visible to the API
    @objc func createViewForParameterID(_ parameterID: UInt32) -> NSView? {
        if parameterID == ParameterID.HueSaturation.rawValue {
            // Make this sized correctly with ColorWheelSize
            let view = ColorCorrectorView(frame: NSRect(x: 0, y: 0, width: 200, height: 200), apiManager: self._apiManager)
            
            // The API expects an unmanaged, over-retained reference. Apple's sample code doesn't use ARC, which is why it works.
            let managed = Unmanaged.passRetained(view)
            return managed.takeUnretainedValue()
        }
        return nil
    }
    
    @objc func `class`(forCustomParameterID parameterID: UInt32) -> AnyClass {
        if parameterID == ParameterID.HueSaturation.rawValue {
            return HueSaturation.self
        }
        return AnyObject.self
    }

}

