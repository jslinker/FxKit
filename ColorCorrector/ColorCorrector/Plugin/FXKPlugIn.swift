//
//  FXKPlugIn.swift
//  XPC Service
//
//  Created by Joseph Slinker on 9/26/22.
//

import Foundation

// What are static vs dynamic properties?
struct FXKPlugInProperties {
    //---------------------------------------------------------
    // Deprecated, and no longer required in FxPlug 4:
    //
    // * kFxPropertyKey_IsThreadSafe
    // * kFxPropertyKey_MayRemapTime
    // * kFxPropertyKey_PixelIndependent
    // * kFxPropertyKey_PreservesAlpha
    // * kFxPropertyKey_UsesLumaChroma
    // * kFxPropertyKey_UsesNonmatchingTextureLayout
    // * kFxPropertyKey_UsesRationalTime
    //---------------------------------------------------------
    
    //---------------------------------------------------------
    // @const      kFxPropertyKey_NeedsFullBuffer
    // @abstract   A key that determines whether the plug-in needs the entire image to do its
    //             processing, and can't tile its rendering.
    // @discussion This value of this key is a Boolean NSNumber indicating whether this plug-in
    //             needs the entire image to do its processing. Note that setting this value to
    //             YES incurs a significant performance penalty and makes your plug-in
    //             unable to render large input images. The default value is NO.
    //---------------------------------------------------------
    var needsFullBuffer: Bool
    
    //---------------------------------------------------------
    // @const      kFxPropertyKey_VariesWhenParamsAreStatic
    // @abstract   A key that determines whether your rendering varies even when
    //             the parameters remain the same.
    // @discussion The value for this key is a Boolean NSNumber indicating whether this effect
    //             changes its rendering even when the parameters don't change. This can happen if
    //             your rendering is based on timing in addition to parameters, for example. Note that
    //             this property is only checked once when the filter is applied, so it
    //             should go in static properties rather than dynamic properties.
    //---------------------------------------------------------
    var variesWhenParamsAreStatic: Bool
        
    //---------------------------------------------------------
    // @const      kFxPropertyKey_ChangesOutputSize
    // @abstract   A key that determines whether your filter has the ability to change the size
    //             of its output to be different than the size of its input.
    // @discussion The value of this key is a Boolean NSNumber indicating whether your filter
    //             returns an output that has a different size than the input. If not, return "NO"
    //             and your filter's @c -destinationImageRect:sourceImages:pluginState:atTime:error:
    //             method will not be called.
    //---------------------------------------------------------
    var changesOutputSize: Bool
    
    internal init(needsFullBuffer: Bool = false, variesWhenParamsAreStatic: Bool, changesOutputSize: Bool) {
        self.needsFullBuffer = needsFullBuffer
        self.variesWhenParamsAreStatic = variesWhenParamsAreStatic
        self.changesOutputSize = changesOutputSize
    }
    
    func toDictionary() -> NSDictionary {
        return [
            kFxPropertyKey_NeedsFullBuffer: NSNumber(value: self.needsFullBuffer),
            kFxPropertyKey_VariesWhenParamsAreStatic: NSNumber(value: self.variesWhenParamsAreStatic),
            kFxPropertyKey_ChangesOutputSize: NSNumber(value: self.changesOutputSize)
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
