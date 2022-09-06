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
    case NextInstance
    case PreviousInstance
}

@objc(ColorCorrectorPlugIn) class ColorCorrectorPlugIn : NSObject, FxTileableEffect {
    
    static let CCPNoCommandQueueError: FxError = kFxError_ThirdPartyDeveloperStart + 1000
    
    private static var gInstanceList: CCPInstanceList = CCPInstanceList()
    
    private let _apiManager : PROAPIAccessing!
    
    private var customView: NSView? = nil
    
    required init?(apiManager: PROAPIAccessing) {
        _apiManager = apiManager
    }
    
    deinit {
        ColorCorrectorPlugIn.gInstanceList.removeInstance(plugin: self)
    }
    
    // MARK: FxTileableEffect Protocol
    
    // Called whenever a new instance of the plugin is added to a users document. The original sample project used the `dispatch_once` pattern to initialize `gInstanceList` here. In Swift this is unnecessary because static variables are already lazily initialized.
    func pluginInstanceAddedToDocument() {
        ColorCorrectorPlugIn.gInstanceList.addInstance(plugin: self)
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
        
        // [UInt32(kFxParameterFlag_CUSTOM_UI) | UInt32(kFxParameterFlag_DONT_DISPLAY_IN_DASHBOARD)])
        let parameterFlags = UInt32(kFxParameterFlag_CUSTOM_UI) | UInt32(kFxParameterFlag_DONT_DISPLAY_IN_DASHBOARD)
        paramAPI.addCustomParameter(withName: hueSatName, parameterID: ParameterID.HueSaturation.rawValue,
                                    defaultValue: defaultColor,
                                    parameterFlags: parameterFlags)
        
        paramAPI.addFloatSlider(withName: "Color Value", parameterID: ParameterID.Value.rawValue, defaultValue: 1.0, parameterMin: 0.0, parameterMax: 100.0, sliderMin: 0.0, sliderMax: 5.0, delta: 0.1, parameterFlags: FxParameterFlags(kFxParameterFlag_DEFAULT))
        
        paramAPI.addFloatSlider(withName: "Brightness", parameterID: ParameterID.NextInstance.rawValue, defaultValue: 1.0, parameterMin: 0.0, parameterMax: 100.0, sliderMin: 0.0, sliderMax: 5.0, delta: 0.1, parameterFlags: FxParameterFlags(kFxParameterFlag_DEFAULT))
    }
    
    func pluginState(_ pluginState: AutoreleasingUnsafeMutablePointer<NSData>?, at renderTime: CMTime, quality qualityLevel: UInt) throws {
        let paramAPI = _apiManager!.api(for: FxParameterRetrievalAPI_v6.self) as! FxParameterRetrievalAPI_v6
        
        var brightness = 1.0
        paramAPI.getFloatValue(&brightness, fromParameter: 1, at: renderTime)
        
        pluginState?.pointee = NSData.init(bytes: &brightness, length: MemoryLayout.size(ofValue: brightness))
    }
    
    func destinationImageRect(_ destinationImageRect: UnsafeMutablePointer<FxRect>, sourceImages: [FxImageTile], destinationImage: FxImageTile, pluginState: Data?, at renderTime: CMTime) throws {
        destinationImageRect.pointee = sourceImages[0].imagePixelBounds
    }
    
    func sourceTileRect(_ sourceTileRect: UnsafeMutablePointer<FxRect>, sourceImageIndex: UInt, sourceImages: [FxImageTile], destinationTileRect: FxRect, destinationImage: FxImageTile, pluginState: Data?, at renderTime: CMTime) throws {
        sourceTileRect.pointee = destinationTileRect;
    }
    
    func renderDestinationImage(_ destinationImage: FxImageTile, sourceImages: [FxImageTile], pluginState: Data?, at renderTime: CMTime) throws {
        // Get the brightness from our plug-in state as a Double
        let brightness = pluginState?.withUnsafeBytes{ (ptr: UnsafeRawBufferPointer) in
            return ptr.bindMemory(to: Double.self).baseAddress?.pointee
        }
        
        let deviceCache = MetalDeviceCache.deviceCache
        let pixelFormat = MetalDeviceCache.FxMTLPixelFormat(for: destinationImage)
        let commandQueue = deviceCache.commandQueue(with: sourceImages[0].deviceRegistryID, pixelFormat: pixelFormat)!

        let commandBuffer = commandQueue.makeCommandBuffer()!
        commandBuffer.label = "ColorCorrector Command Buffer"
        commandBuffer.enqueue()
        
        let inputTexture = sourceImages[0].metalTexture(for: deviceCache.device(with: sourceImages[0].deviceRegistryID))
        let outputTexture = destinationImage.metalTexture(for: deviceCache.device(with: destinationImage.deviceRegistryID))
        
        let colorAttachmentDescriptor = MTLRenderPassColorAttachmentDescriptor.init()
        colorAttachmentDescriptor.texture = outputTexture
        colorAttachmentDescriptor.clearColor = MTLClearColorMake(1.0, 0.5, 0.0, 1.0)
        colorAttachmentDescriptor.loadAction = MTLLoadAction.clear
        let renderPassDescriptor = MTLRenderPassDescriptor.init()
        renderPassDescriptor.colorAttachments [ 0 ] = colorAttachmentDescriptor
        let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        
        // Do rendering
        let outputWidth = destinationImage.tilePixelBounds.right - destinationImage.tilePixelBounds.left
        let outputHeight = destinationImage.tilePixelBounds.top - destinationImage.tilePixelBounds.bottom
        var vertices = [
            Vertex2D(position: vector_float2(Float(outputWidth) / 2.0, Float(-outputHeight) / 2.0), textureCoordinate: vector_float2(1.0, 1.0)),
            Vertex2D(position: vector_float2(Float(-outputWidth) / 2.0, Float(-outputHeight) / 2.0), textureCoordinate: vector_float2(0.0, 1.0)),
            Vertex2D(position: vector_float2(Float(outputWidth) / 2.0, Float(outputHeight) / 2.0), textureCoordinate: vector_float2(1.0, 0.0)),
            Vertex2D(position: vector_float2(Float(-outputWidth) / 2.0, Float(outputHeight) / 2.0), textureCoordinate: vector_float2(0.0, 0.0))
        ]
        
        let viewport = MTLViewport(originX: 0, originY: 0, width: Double(outputWidth), height: Double(outputHeight), znear: -1.0, zfar: 1.0)
        commandEncoder.setViewport(viewport)
        
        let pipelineState = deviceCache.pipelineState(with: sourceImages[0].deviceRegistryID, pixelFormat: pixelFormat)
        commandEncoder.setRenderPipelineState(pipelineState!)
        
        commandEncoder.setVertexBytes(&vertices, length: MemoryLayout<Vertex2D>.size * 4, index: Int(BVI_Vertices.rawValue))
        
        var viewportSize = simd_uint2(UInt32(outputWidth), UInt32(outputHeight))
        commandEncoder.setVertexBytes(&viewportSize, length: MemoryLayout.size(ofValue: viewportSize), index: Int(BVI_ViewportSize.rawValue))
        
        commandEncoder.setFragmentTexture(inputTexture, index: Int(BTI_InputImage.rawValue))
        
        var fragmentBrightness = Float(brightness!)
        commandEncoder.setFragmentBytes(&fragmentBrightness, length: MemoryLayout.size(ofValue: fragmentBrightness), index: Int(BFI_Brightness.rawValue))
        
        commandEncoder.drawPrimitives(type: MTLPrimitiveType.triangleStrip, vertexStart: 0, vertexCount: 4)
        
        // Clean up
        commandEncoder.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        
        deviceCache.returnCommandQueueToCache(commandQueue: commandQueue)
    }
    
    // Who knows if this function name is correct. The @objc was essential to making this visible to the API
    @objc func createViewForParameterID(_ parameterID: UInt32) -> NSView? {
        if parameterID == ParameterID.HueSaturation.rawValue {
            // Make this sized correctly with ColorWheelSize
            self.customView = ColorCorrectorView(frame: NSRect(x: 0, y: 0, width: 200, height: 200), apiManager: self._apiManager)
        }
        return self.customView
    }
    
    @objc func `class`(forCustomParameterID parameterID: UInt32) -> AnyClass {
        if parameterID == ParameterID.HueSaturation.rawValue {
            return HueSaturation.self
        }
        return AnyObject.self
    }

}
