//
//  FXKPlugIn.swift
//  XPC Service
//
//  Created by Joseph Slinker on 9/26/22.
//

import Foundation

// What are static vs dynamic properties?
struct FXKPlugInProperties {
    
    // This appears in some documentation, but is deprecated
//    var equivalentSMPTEWipeCode: Int
//    var mayRemapTime: Bool
    var pixelIndependent: Bool
    var preservesAlpha: Bool
    // This is deprecated in FXPlug 4 but isn't clearly indicated in documentation
//    var isThreadSafe: Bool
    var needsFullBuffer: Bool
    var variesWhenParamsAreStatic: Bool
    var changesOutputSize: Bool
    // This is used in the sample projects, and is filed under "deprecated" in the documentation, but is not explicitly marked as deprecated
//    var transformSupprot: FxPixelTransformSupport
    
    internal init(pixelIndependent: Bool = false, preservesAlpha: Bool = false, needsFullBuffer: Bool = false, variesWhenParamsAreStatic: Bool, changesOutputSize: Bool) {
        self.pixelIndependent = pixelIndependent
        self.preservesAlpha = preservesAlpha
        self.needsFullBuffer = needsFullBuffer
        self.variesWhenParamsAreStatic = variesWhenParamsAreStatic
        self.changesOutputSize = changesOutputSize
    }
    
    func toDictionary() -> NSDictionary {
        return [
            kFxPropertyKey_PixelIndependent: NSNumber(value: self.pixelIndependent),
            kFxPropertyKey_PreservesAlpha: NSNumber(value: self.preservesAlpha),
            kFxPropertyKey_NeedsFullBuffer: NSNumber(value: self.needsFullBuffer),
            kFxPropertyKey_VariesWhenParamsAreStatic: NSNumber(value: self.variesWhenParamsAreStatic),
            kFxPropertyKey_ChangesOutputSize: NSNumber(value: self.changesOutputSize),
        ]
    }
    
}

struct FXKRectRequest {
    var sourceImageIndex: UInt
    var sourceImages: [FxImageTile]
    var destinationTileRect: FxRect
    var destinationImage: FxImageTile
    var pluginState: Date?
    var renderTime: CMTime
}

class FXKPlugIn {
    
    internal let apiManager: PROAPIAccessing
    
    internal let properties: FXKPlugInProperties
    
    internal let parameters: [FXKPlugInParameter]
    
    init(apiManager: PROAPIAccessing, properties: FXKPlugInProperties, parameters: [FXKPlugInParameter]) {
        self.apiManager = apiManager
        self.properties = properties
        self.parameters = parameters
    }
    
    func pluginInstanceAddedToDocument() {
        
    }
    
    func pluginStateAt(_ renderTime: CMTime, quality: FxQuality) throws -> NSData? {
        assertionFailure("Subclasses must implement \(#function)")
        throw NSError(domain: "Not implemented", code: 0)
    }
    
    func destinationImageRectFor(request: FXKRectRequest) throws -> FxRect {
        assertionFailure("Subclasses must implement \(#function)")
        throw NSError(domain: "Not implemented", code: 0)
    }
    
    func sourceTileRectFor(request: FXKRectRequest) throws -> FxRect {
        assertionFailure("Subclasses must implement \(#function)")
        throw NSError(domain: "Not implemented", code: 0)
    }
    
    func renderDestinationImageFor(request: FXKRectRequest) throws {
        assertionFailure("Subclasses must implement \(#function)")
        throw NSError(domain: "Not implemented", code: 0)
    }
    
    func createViewForParameterID(_ parameterID: UInt32) -> NSView? {
        assertionFailure("Subclasses must implement \(#function)")
        return nil
    }
    
}
