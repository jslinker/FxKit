//
//  FXKPlugInParameter.swift
//  XPC Service
//
//  Created by Joseph Slinker on 9/27/22.
//

import Foundation

struct FXKParameterRange<T: Numeric> {
    var min: T
    var max: T
}

class FXKPlugInParameter {
    /// Parameter IDs must be in the range of [1, 9998]. IDs outside of this range are invalid.
    var id: UInt32
    var flags: FxParameterFlags
    var name: String
    
    internal init(name: String, id: UInt32, flags: FxParameterFlags) {
        assert(id >= 1 && id <= 9998)
        self.name = name
        self.id = id
        self.flags = flags
    }
    
    /// To be implemented by subclasses. The plugin call this funciton to make the parameter available to Motion. The default implementation is a no-op.
    func addTo(apiManager: FxParameterCreationAPI_v5) {
        assertionFailure("\(#function) should be implemented by subclasses. Are you using the correct class for your parameter type?")
    }
    
}

//func addAngleSlider(withName: String, parameterID: UInt32, defaultDegrees: Double, parameterMinDegrees: Double, parameterMaxDegrees: Double, parameterFlags: FxParameterFlags) -> Bool
//Creates an angle slider parameter and adds it to the plug-in's parameter list.
//Required.
class FXKAngleSliderParameter: FXKPlugInParameter {
    
    var defaultDegress: Double
    var minDegrees: Double
    var maxDegrees: Double
    
    internal init(name: String, id: UInt32, flags: FxParameterFlags, defaultDegress: Double, range: FXKParameterRange<Double>) {
        self.defaultDegress = defaultDegress
        self.minDegrees = range.min
        self.maxDegrees = range.max
        super.init(name: name, id: id, flags: flags)
    }
    
    override func addTo(apiManager: FxParameterCreationAPI_v5) {
        apiManager.addAngleSlider(withName: self.name, parameterID: self.id, defaultDegrees: self.defaultDegress, parameterMinDegrees: self.minDegrees, parameterMaxDegrees: self.maxDegrees, parameterFlags: self.flags)
    }
    
}

//func addColorParameter(withName: String, parameterID: UInt32, defaultRed: Double, defaultGreen: Double, defaultBlue: Double, defaultAlpha: Double, parameterFlags: FxParameterFlags) -> Bool
//Creates an RGBA color value and adds it to the plug-in's parameter list.
//Required.

//func addColorParameter(withName: String, parameterID: UInt32, defaultRed: Double, defaultGreen: Double, defaultBlue: Double, parameterFlags: FxParameterFlags) -> Bool
//Creates an RGB color parameter and adds it to the plug-in's parameter list.
//Required.
class FXKColorParameter: FXKPlugInParameter {
    
    var red: Double
    var green: Double
    var blue: Double
    var alpha: Double
    
    internal init(name: String, id: UInt32, flags: FxParameterFlags, red: Double, green: Double, blue: Double, alpha: Double) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
        super.init(name: name, id: id, flags: flags)
    }
    
    override func addTo(apiManager: FxParameterCreationAPI_v5) {
        apiManager.addColorParameter(withName: self.name, parameterID: self.id, defaultRed: self.red, defaultGreen: self.green, defaultBlue: self.blue, defaultAlpha: self.alpha, parameterFlags: self.flags)
    }
    
}

//func addCustomParameter(withName: String, parameterID: UInt32, defaultValue: NSCopying & NSSecureCoding & NSObjectProtocol, parameterFlags: FxParameterFlags) -> Bool
//Creates a custom parameter and adds it to the plug-in's parameter list.
//Required.
class FXKCustomParameter: FXKPlugInParameter {
    
    var defaultValue: NSCopying & NSSecureCoding & NSObjectProtocol
    
    internal init(name: String, id: UInt32, flags: FxParameterFlags, defaultValue: NSCopying & NSSecureCoding & NSObjectProtocol) {
        self.defaultValue = defaultValue
        super.init(name: name, id: id, flags: flags)
    }
    
    override func addTo(apiManager: FxParameterCreationAPI_v5) {
        apiManager.addCustomParameter(withName: self.name, parameterID: self.id, defaultValue: self.defaultValue, parameterFlags: self.flags)
    }
    
}

class FXKSliderParameter<T: Numeric>: FXKPlugInParameter {
    
    var defaultValue: T
    var parameterMin: T
    var parameterMax: T
    var sliderMin: T
    var sliderMax: T
    var delta: T
    
    internal init(name: String, id: UInt32, flags: FxParameterFlags, defaultValue: T, parameterRange: FXKParameterRange<T>, sliderRange: FXKParameterRange<T>, delta: T) {
        self.defaultValue = defaultValue
        self.parameterMin = parameterRange.min
        self.parameterMax = parameterRange.max
        self.sliderMin = sliderRange.min
        self.sliderMax = sliderRange.max
        self.delta = delta
        super.init(name: name, id: id, flags: flags)
    }
    
    override func addTo(apiManager: FxParameterCreationAPI_v5) {
        assertionFailure("FXKSliderParameter should not be used directly. Use a specialized type like `FXKFloatSliderParameter`.")
    }
    
}

//func addFloatSlider(withName: String, parameterID: UInt32, defaultValue: Double, parameterMin: Double, parameterMax: Double, sliderMin: Double, sliderMax: Double, delta: Double, parameterFlags: FxParameterFlags) -> Bool
//Creates a floating point slider parameter and adds it to the plug-in's parameter list.
//Required.
class FXKFloatSliderParameter: FXKSliderParameter<Double> {
    
    override func addTo(apiManager: FxParameterCreationAPI_v5) {
        apiManager.addFloatSlider(withName: self.name, parameterID: self.id, defaultValue: self.defaultValue, parameterMin: self.parameterMin, parameterMax: self.parameterMax, sliderMin: self.sliderMin, sliderMax: self.sliderMax, delta: self.delta, parameterFlags: self.flags)
    }
    
    override func toDataFrom(apiManager: FxParameterRetrievalAPI_v6, at time: CMTime) -> NSData? {
        var value: Double = 0.0
        apiManager.getFloatValue(&value, fromParameter: self.id, at: time)
        return NSData(bytes: &value, length: MemoryLayout.size(ofValue: Double.self))
    }
    
}

//func addFontMenu(withName: String, parameterID: UInt32, fontName: String, parameterFlags: FxParameterFlags) -> Bool
//Creates a help push button parameter and adds it to the plug-in's parameter.
//Required.
class FXKFontMenuParameter: FXKPlugInParameter {
    
    var fontName: String
    
    init(name: String, id: UInt32, flags: FxParameterFlags, fontName: String) {
        self.fontName = fontName
        super.init(name: name, id: id, flags: flags)
    }
    
    override func addTo(apiManager: FxParameterCreationAPI_v5) {
        apiManager.addFontMenu(withName: self.name, parameterID: self.id, fontName: self.fontName, parameterFlags: self.flags)
    }
    
}

//func addGradient(withName: String, parameterID: UInt32, parameterFlags: FxParameterFlags) -> Bool
//Creates a gradient parameter.
//Required.
// TODO: Figure out how to read the gradient parameter from the API
class FXKGradientParameter: FXKPlugInParameter {
    
    override func addTo(apiManager: FxParameterCreationAPI_v5) {
        apiManager.addGradient(withName: self.name, parameterID: self.id, parameterFlags: self.flags)
    }
    
}

//func addHelpButton(withName: String, parameterID: UInt32, selector: Selector, parameterFlags: FxParameterFlags) -> Bool
//Creates a help push button parameter and adds it to the plug-in's parameter.
//Required.
class FXKHelpButtonParameter: FXKPlugInParameter {
    
    var selector: Selector
    
    init(name: String, id: UInt32, flags: FxParameterFlags, selector: Selector) {
        self.selector = selector
        super.init(name: name, id: id, flags: flags)
    }
    
    override func addTo(apiManager: FxParameterCreationAPI_v5) {
        apiManager.addHelpButton(withName: self.name, parameterID: self.id, selector: self.selector, parameterFlags: self.flags)
    }
    
}

//func addHistogram(withName: String, parameterID: UInt32, parameterFlags: FxParameterFlags) -> Bool
//Creates a histogram parameter.
//Required.
// TODO: Figure out how to read and write histogram data
class FXKHistogramParameter: FXKPlugInParameter {
    
    override func addTo(apiManager: FxParameterCreationAPI_v5) {
        apiManager.addHistogram(withName: self.name, parameterID: self.id, parameterFlags: self.flags)
    }
    
}

//func addImageReference(withName: String, parameterID: UInt32, parameterFlags: FxParameterFlags) -> Bool
//Creates an image reference parameter and adds it to the plug-in's parameter list.
//Required.
// TODO: Figure out how to read and write image references
class FXKImageReferenceParameter: FXKPlugInParameter {
    
    override func addTo(apiManager: FxParameterCreationAPI_v5) {
        apiManager.addImageReference(withName: self.name, parameterID: self.id, parameterFlags: self.flags)
    }
    
}

//func addIntSlider(withName: String, parameterID: UInt32, defaultValue: Int32, parameterMin: Int32, parameterMax: Int32, sliderMin: Int32, sliderMax: Int32, delta: Int32, parameterFlags: FxParameterFlags) -> Bool
//Creates an integer slider parameter and adds it to the plug-in's parameter list.
//Required.
class FXKIntSliderParameter: FXKSliderParameter<Int32> {
    
    override func addTo(apiManager: FxParameterCreationAPI_v5) {
        apiManager.addIntSlider(withName: self.name, parameterID: self.id, defaultValue: self.defaultValue, parameterMin: self.parameterMin, parameterMax: self.parameterMax, sliderMin: self.sliderMin, sliderMax: self.sliderMax, delta: self.delta, parameterFlags: self.flags)
    }
    
}

//func addPathPicker(withName: String, parameterID: UInt32, parameterFlags: FxParameterFlags) -> Bool
//Creates a parameter for choosing an image mask path.
//Required.
// TODO: Figure out how to read and write path masks
class FXKPathPickerParameter: FXKPlugInParameter {
    
    override func addTo(apiManager: FxParameterCreationAPI_v5) {
        apiManager.addPathPicker(withName: self.name, parameterID: self.id, parameterFlags: self.flags)
    }
    
}

//func addPercentSlider(withName: String, parameterID: UInt32, defaultValue: Double, parameterMin: Double, parameterMax: Double, sliderMin: Double, sliderMax: Double, delta: Double, parameterFlags: FxParameterFlags) -> Bool
//Creates a percentage floating point slider parameter and adds it to the plug-in's parameter list. A parameter value of 1.0 corresponds to a slider value of 100%.
//Required.
class FXKPercentSliderParameter: FXKSliderParameter<Double> {
    
    override func addTo(apiManager: FxParameterCreationAPI_v5) {
        apiManager.addPercentSlider(withName: self.name, parameterID: self.id, defaultValue: self.defaultValue, parameterMin: self.parameterMin, parameterMax: self.parameterMax, sliderMin: self.sliderMin, sliderMax: self.sliderMax, delta: self.delta, parameterFlags: self.flags)
    }
    
}

//func addPointParameter(withName: String, parameterID: UInt32, defaultX: Double, defaultY: Double, parameterFlags: FxParameterFlags) -> Bool
//Creates a position point parameter and adds it to the plug-in's parameter list.
//Required.
class FXKPointParameter: FXKPlugInParameter {
    
    var x: Double
    var y: Double
    
    init(name: String, id: UInt32, flags: FxParameterFlags, x: Double, y: Double) {
        self.x = x
        self.y = y
        super.init(name: name, id: id, flags: flags)
    }
    
    override func addTo(apiManager: FxParameterCreationAPI_v5) {
        apiManager.addPointParameter(withName: self.name, parameterID: self.id, defaultX: self.x, defaultY: self.y, parameterFlags: self.flags)
    }
    
}

//func addPopupMenu(withName: String, parameterID: UInt32, defaultValue: UInt32, menuEntries: [Any], parameterFlags: FxParameterFlags) -> Bool
//Creates a popup menu parameter and adds it to the plug-in's parameter list.
//Required.
// TODO: Figure out how to read and write menu selections
class FXKPopupMenuParameter: FXKPlugInParameter {
    
    var defaultSelection: UInt32
    // TODO: Change from Any to whatever type actually works
    var menuEntries: [Any]
    
    init(name: String, id: UInt32, flags: FxParameterFlags, defaultSelection: UInt32, menuEntries: [Any]) {
        self.defaultSelection = defaultSelection
        self.menuEntries = menuEntries
        super.init(name: name, id: id, flags: flags)
    }
    
    override func addTo(apiManager: FxParameterCreationAPI_v5) {
        apiManager.addPopupMenu(withName: self.name, parameterID: self.id, defaultValue: self.defaultSelection, menuEntries: self.menuEntries, parameterFlags: self.flags)
    }
    
}

//func addPushButton(withName: String, parameterID: UInt32, selector: Selector, parameterFlags: FxParameterFlags) -> Bool
//Creates a push button parameter and adds it to the plug-in's parameter list.
//Required.
class FXKPushButtonParameter: FXKPlugInParameter {
    
    /// The required initializer for FXKPushButtonParameter
    /// - Parameters:
    ///   - name: User readable name
    ///   - id: Unique, consistent identifer for the parameter
    ///   - flags: Parameter flags
    ///   - selector: A selector to be called on the _plugin_ object when the button is pressed
    internal init(name: String, id: UInt32, flags: FxParameterFlags, selector: Selector) {
        self.selector = selector
        super.init(name: name, id: id, flags: flags)
    }
    
    var selector: Selector
    
    override func addTo(apiManager: FxParameterCreationAPI_v5) {
        apiManager.addPushButton(withName: self.name, parameterID: self.id, selector: self.selector, parameterFlags: self.flags)
    }
    
    override func toDataFrom(apiManager: FxParameterRetrievalAPI_v6, at time: CMTime) -> NSData? {
        return nil
    }
    
}

//func addStringParameter(withName: String, parameterID: UInt32, defaultValue: String, parameterFlags: FxParameterFlags) -> Bool
//Creates a string parameter and adds it to the plug-in's parameter list.
//Required.
class FXKStringParameter: FXKPlugInParameter {
    
    var defaultValue: String
    
    init(name: String, id: UInt32, flags: FxParameterFlags, defaultValue: String) {
        self.defaultValue = defaultValue
        super.init(name: name, id: id, flags: flags)
    }
    
    override func addTo(apiManager: FxParameterCreationAPI_v5) {
        apiManager.addStringParameter(withName: self.name, parameterID: self.id, defaultValue: self.defaultValue, parameterFlags: self.flags)
    }
    
}

//func addToggleButton(withName: String, parameterID: UInt32, defaultValue: Bool, parameterFlags: FxParameterFlags) -> Bool
//Creates a checkbox toggle button parameter and adds it to the plug-in's parameter.
//Required.
class FXKToggleButtonParameter: FXKPlugInParameter {
    
    var defaultValue: Bool
    
    init(name: String, id: UInt32, flags: FxParameterFlags, defaultValue: Bool) {
        self.defaultValue = defaultValue
        super.init(name: name, id: id, flags: flags)
    }
    
    override func addTo(apiManager: FxParameterCreationAPI_v5) {
        apiManager.addToggleButton(withName: self.name, parameterID: self.id, defaultValue: self.defaultValue, parameterFlags: self.flags)
    }
    
}

//func startParameterSubGroup(String, parameterID: UInt32, parameterFlags: FxParameterFlags) -> Bool
//Starts a new parameter subgroup. All subsequent parameter additions are placed in this group until you send an endParameterSubGroup() message.
//Required.
class FXKStartParameterSubGroupParameter: FXKPlugInParameter {
    
    override func toDataFrom(apiManager: FxParameterRetrievalAPI_v6, at time: CMTime) -> NSData? {
        return nil
    }
    
    override func addTo(apiManager: FxParameterCreationAPI_v5) {
        apiManager.startParameterSubGroup(self.name, parameterID: self.id, parameterFlags: self.flags)
    }
    
}

//func endParameterSubGroup() -> Bool
//Closes current parameter subgroup. You should always pair this with a preceding startParameterSubGroup(_:parameterID:parameterFlags:) message.
//Required.
class FXKEndParameterSubGroupParameter: FXKPlugInParameter {
    
    override func toDataFrom(apiManager: FxParameterRetrievalAPI_v6, at time: CMTime) -> NSData? {
        return nil
    }
    
    override func addTo(apiManager: FxParameterCreationAPI_v5) {
        apiManager.endParameterSubGroup()
    }
    
}
