//
//  ColorCorrectorView.swift
//  ColorCorrector
//
//  Created by Joseph Slinker on 6/21/22.
//

import Foundation
import MetalKit

// These are lossy because the APIs that consume them require Ints sometimes. Figure out something not lossy here.
fileprivate let ColorWheelSize: CGFloat = 200
fileprivate let KnobSize: CGFloat = 10
fileprivate let KnobRadius: CGFloat = KnobSize / 2
fileprivate let WheelRadius: CGFloat = ColorWheelSize / 2
fileprivate let WheelCenter: NSPoint = NSPoint(x: WheelRadius, y: WheelRadius)

class ColorCorrectorView: NSView, MTKViewDelegate {
    
//    enum ParameterID: UInt32 {
//        case HueSaturation = 1
//        case Value, WindowButton, NextInstance, PreviousInstance
//    }
    
    private let apiManager: PROAPIAccessing
    
    private let metalView: MTKView
    private let commandQueue: MTLCommandQueue
    
    init(frame: NSRect, apiManager: PROAPIAccessing) {
        self.apiManager = apiManager
        let device = MTLCreateSystemDefaultDevice()!
        self.commandQueue = device.makeCommandQueue()!
        self.metalView = MTKView(frame: CGRect.zero, device: device)
        
        super.init(frame: frame)
        self.metalView.clearColor = MTLClearColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1)
        self.metalView.enableSetNeedsDisplay = true
        self.metalView.isPaused = true
        self.metalView.delegate = self
        self.addSubview(self.metalView)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layout() {
        super.layout()
        self.metalView.frame = self.bounds
    }
    
    // MARK: - Metal
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // Save the size?
    }
    
    func draw(in view: MTKView) {
        let descriptor = view.currentRenderPassDescriptor!
        let buffer = self.commandQueue.makeCommandBuffer()!
        let commandEncoder = buffer.makeRenderCommandEncoder(descriptor: descriptor)!
        
        // Do stuff
        
        commandEncoder.endEncoding()
        let drawable = view.currentDrawable!
        buffer.present(drawable)
        buffer.commit()
    }
    
    // MARK: - Drawing
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        ColorCorrectorView.hueSaturationWheel.draw(in: self.bounds)
        
        // Read the Hue and Saturation at the current frame
        let actionAPI = self.apiManager.api(for: FxCustomParameterActionAPI_v4.self) as! FxCustomParameterActionAPI_v4
        actionAPI.startAction(self)
        
        let currentTime = actionAPI.currentTime()
        
        let hueSat = HueSaturation.fromAPI(self.apiManager, forParameter: ParameterID.HueSaturation.rawValue, at: currentTime)
        
        // This didn't work, why? Just crashes for some reason.
//        let paramAPI = self.apiManager.api(for: FxParameterRetrievalAPI_v6.self) as! FxParameterRetrievalAPI_v6
//        let parameterPointer: AutoreleasingUnsafeMutablePointer<NSCopying & NSSecureCoding & NSObjectProtocol>? = nil
//        paramAPI.getCustomParameterValue(parameterPointer, fromParameter: ParameterID.HueSaturation.rawValue, at: currentTime)
//        let hueSat: HueSaturation! = parameterPointer!.pointee as! HueSaturation
        
        actionAPI.endAction(self)

        // Draw the knob
        let knobPoint = CGPoint(x: WheelRadius + hueSat.saturation * WheelRadius * cos(hueSat.hue),
                                y: WheelRadius + hueSat.saturation * WheelRadius * sin(hueSat.hue))
        let knobRect = NSRect(x: 0, y: 0, width: KnobSize, height: KnobSize)
            .offsetBy(dx: -KnobRadius, dy: -KnobRadius)
            .offsetBy(dx: knobPoint.x, dy: knobPoint.y)
        ColorCorrectorView.knobImage.draw(in: knobRect)
    }
    
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }
    
    override func mouseDown(with event: NSEvent) {
        self.mouseDragged(with: event)
    }
    
    override func mouseUp(with event: NSEvent) {
        self.mouseDragged(with: event)
    }
    
    override func mouseDragged(with event: NSEvent) {
        let clickPoint = self.convert(event.locationInWindow, to: nil)
        let delta = NSPoint(x: clickPoint.x - WheelCenter.x, y: clickPoint.y - WheelCenter.y)
        
        var distance = sqrt(delta.x * delta.x + delta.y * delta.y)
        if distance > 1 { distance = 1 }
        
        var hueRadians = atan2(delta.y, delta.x)
        if hueRadians < 0 { hueRadians += Double.pi * 2 }
        
        let actionAPI = self.apiManager.api(for: FxCustomParameterActionAPI_v4.self) as! FxCustomParameterActionAPI_v4
        actionAPI.startAction(self)
        
        let currentTime = actionAPI.currentTime()

        HueSaturation.setFromAPI(self.apiManager, withID: ParameterID.HueSaturation.rawValue, hueRadians: hueRadians, saturation: distance, at: currentTime)

        actionAPI.endAction(self)

        self.needsDisplay = true
    }
        
    static let hueSaturationWheel: NSImage = {
        let sRGB = CGColorSpace(name: CGColorSpace.sRGB)!
        let bitmapContext = CGContext(data: nil,
                                      width: Int(ColorWheelSize), height: Int(ColorWheelSize),
                                      bitsPerComponent: 8, bytesPerRow: Int(ColorWheelSize) * 4,
                                      space: sRGB,
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!

        let baseAddress = bitmapContext.data!
        let rowBytes = bitmapContext.bytesPerRow
        
        for row in 0..<Int(ColorWheelSize) {
            var nextPixel = baseAddress + (row * rowBytes)
            for col in 0..<Int(ColorWheelSize) {
                let x = CGFloat(col) - WheelRadius
                let y = ColorWheelSize - CGFloat(row) - WheelRadius
                var hue = atan2(y, x)
                let sat = sqrt(x * x + y * y) / WheelRadius
                var red = 0.0
                var green = 0.0
                var blue = 0.0
                
                if sat <= 1 {
                    if hue < 0 {
                        hue += CGFloat.pi * 2
                    }
                    HSVToRGB(hue: hue, saturation: sat, value: 1.0, red: &red, green: &green, blue: &blue)
                }
                
                let alpha = min(max(WheelRadius - (sat * WheelRadius), 0), 1)
                nextPixel.storeBytes(of: (UInt8)(red * alpha * 255.0), as: UInt8.self)
                nextPixel += 1
                nextPixel.storeBytes(of: (UInt8)(green * alpha * 255.0), as: UInt8.self)
                nextPixel += 1
                nextPixel.storeBytes(of: (UInt8)(blue * alpha * 255.0), as: UInt8.self)
                nextPixel += 1
                nextPixel.storeBytes(of: (UInt8)(alpha * 255.0), as: UInt8.self)
                nextPixel += 1
            }
        }
        
        let hueSatImage = bitmapContext.makeImage()!
        let colorWheel = NSImage(cgImage: hueSatImage, size: NSSize(width: ColorWheelSize, height: ColorWheelSize))
        return colorWheel
    }()
    
    static let knobImage: NSImage = {
        let sRGB = CGColorSpace(name: CGColorSpace.sRGB)!
        let bitmapContext = CGContext(data: nil,
                                      width: Int(KnobSize), height: Int(KnobSize),
                                      bitsPerComponent: 8, bytesPerRow: Int(KnobSize) * 4,
                                      space: sRGB,
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        // Draw the knob
        let knobBounds = CGRect(x: 0, y: 0, width: KnobSize, height: KnobSize)
        let knobPath = CGPath(ellipseIn: knobBounds, transform: nil)
        bitmapContext.setFillColor(NSColor.black.withAlphaComponent(0).cgColor)
        bitmapContext.fill(knobBounds)
        bitmapContext.saveGState()
        bitmapContext.addPath(knobPath)
        bitmapContext.setFillColor(CGColor.white)
        bitmapContext.fillPath()
        bitmapContext.restoreGState()
        
        // Draw an outline around the knob
        let outlinePath = CGPath(ellipseIn: knobBounds.insetBy(dx: 1, dy: 1), transform: nil)
        bitmapContext.addPath(outlinePath)
        bitmapContext.setStrokeColor(CGColor.black)
        bitmapContext.setLineWidth(1)
        bitmapContext.strokePath()
        
        let cgImage = bitmapContext.makeImage()!
        return NSImage(cgImage: cgImage, size: NSSize(width: KnobSize, height: KnobSize))
    }()
}
