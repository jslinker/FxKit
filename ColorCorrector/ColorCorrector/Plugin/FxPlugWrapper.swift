//
//  FxPlugWrapper.swift
//  ColorCorrector
//
//  Created by Joseph Slinker on 9/9/22.
//

import Foundation

extension FxParameterFlags {
    // The API defines FxParameterFlags as UInt32, but the flag definitions are all Int, which makes them incompatible when brought to Swift
    static let Default: FxParameterFlags = FxParameterFlags(kFxParameterFlag_DEFAULT)
    static let NotAnimatable: FxParameterFlags = FxParameterFlags(kFxParameterFlag_NOT_ANIMATABLE)
    static let Hidden: FxParameterFlags = FxParameterFlags(kFxParameterFlag_HIDDEN)
    static let Collapsed: FxParameterFlags = FxParameterFlags(kFxParameterFlag_COLLAPSED)
    static let DontSave: FxParameterFlags = FxParameterFlags(kFxParameterFlag_DONT_SAVE)
    static let DontDisplayInDashboard: FxParameterFlags = FxParameterFlags(kFxParameterFlag_DONT_DISPLAY_IN_DASHBOARD)
    static let CustomUI: FxParameterFlags = FxParameterFlags(kFxParameterFlag_CUSTOM_UI)
    static let IgnoreMinMax: FxParameterFlags = FxParameterFlags(kFxParameterFlag_IGNORE_MINMAX)
    static let CurveEditorHidden: FxParameterFlags = FxParameterFlags(kFxParameterFlag_CURVE_EDITOR_HIDDEN)
    static let DontRemapColors: FxParameterFlags = FxParameterFlags(kFxParameterFlag_DONT_REMAP_COLORS)
    static let UseFullViewWidth: FxParameterFlags = FxParameterFlags(kFxParameterFlag_USE_FULL_VIEW_WIDTH)

}

extension PROAPIAccessing {
    
    func parameterActionAPIV4() -> FxCustomParameterActionAPI_v4? {
        return self.api(for: FxCustomParameterActionAPI_v4.self) as? FxCustomParameterActionAPI_v4
    }
    
    func parameterCreationAPIV5() -> FxParameterCreationAPI_v5? {
        return self.api(for: FxParameterCreationAPI_v5.self) as? FxParameterCreationAPI_v5
    }
    
    func parameterRetrievalAPIV6() -> FxParameterRetrievalAPI_v6? {
        return self.api(for: FxParameterRetrievalAPI_v6.self) as? FxParameterRetrievalAPI_v6
    }
    
    func commandAPIV2() -> FxCommandAPI_v2? {
        return self.api(for: FxCommandAPI_v2.self) as? FxCommandAPI_v2
    }
    
    func timingAPIV4() -> FxTimingAPI_v4? {
        return self.api(for: FxTimingAPI_v4.self) as? FxTimingAPI_v4
    }
    
}

extension FxTimingAPI_v4 {
    
    func startTimeForEffect() -> CMTime {
        var effectTime = CMTime.invalid
        self.startTime(forEffect: &effectTime)
        return effectTime
    }
    
    func timelineTimeFrom(_ inputTime: CMTime) -> CMTime {
        var timelineEffectTime = CMTime.invalid
        self.timelineTime(&timelineEffectTime, fromInputTime: inputTime)
        return timelineEffectTime
    }
    
    func timelineStartTimeForEffect() -> CMTime {
        return self.timelineTimeFrom(self.startTimeForEffect())
    }
}

func dprint(_ items: Any..., separator: String = " ", terminator: String = "\n", file: String = #file, line: Int = #line, function: String = #function) {
    print(items + ["\(file) \(line) \(function)"], separator: separator, terminator: terminator)
}
