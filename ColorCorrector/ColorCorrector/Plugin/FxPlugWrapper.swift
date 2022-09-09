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
