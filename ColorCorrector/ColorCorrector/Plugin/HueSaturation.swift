////
////  HueSaturation.swift
////  ColorCorrector
////
////  Created by Joseph Slinker on 4/27/22.
////
//
//import Foundation
//
//private enum CodingKey: String {
//    case Hue = "CodingKeyHue"
//    case Saturation = "CodingKeySaturation"
//}
//
//class HueSaturation: NSObject, NSSecureCoding, NSCopying, FxCustomParameterInterpolation_v2 {
//    
//    let hue: Double
//    let saturation: Double
//    
//    init(hue: Double, saturation: Double) {
//        self.hue = hue
//        self.saturation = saturation
//    }
//    
//    // MARK: - NSSecureCoding
//    
//    static var supportsSecureCoding: Bool = true
//    
//    // MARK: - NSCopying
//    
//    func copy(with zone: NSZone? = nil) -> Any {
//        return HueSaturation(hue: self.hue, saturation: self.saturation)
//    }
//    
//    // MARK: - NSCoding
//    
//    func encode(with coder: NSCoder) {
//        coder.encode(self.hue, forKey: CodingKey.Hue.rawValue)
//        coder.encode(self.saturation, forKey: CodingKey.Saturation.rawValue)
//    }
//    
//    required init?(coder: NSCoder) {
//        super.init()
//        self.hue = coder.decodeDouble(forKey: CodingKey.Hue.rawValue)
//        self.saturation = coder.decodeDouble(forKey: CodingKey.Saturation.rawValue)
//    }
//    
//    // MARK: - FxCustomParameterInterpolation_v2
//    
//    func interpolateBetween(_ rightValue: NSCopying & NSSecureCoding & NSObjectProtocol, withWeight weight: Float) -> NSCopying & NSSecureCoding & NSObjectProtocol {
//        let rhs = rightValue as! HueSaturation
//        let weight = Double(weight)
//        let newHue = fmod(self.hue + (rhs.hue - self.hue) * weight, Double.pi * 2.0)
//        let newSaturation = self.saturation + (rhs.saturation - self.saturation) * weight
//        return HueSaturation(hue: newHue, saturation: newSaturation)
//    }
//    
//    @objc func isEqual(_ rightValue: NSCopying & NSSecureCoding & NSObjectProtocol) -> Bool {
//        let rhs = rightValue as! HueSaturation
//        return self.hue == rhs.hue && self.saturation == rhs.saturation
//    }
//    
////    override func isEqual(_ object: Any?) -> Bool {
////        guard let rhs = object as? HueSaturation else { return false }
////        return self.hue == rhs.hue && self.saturation == rhs.saturation
////    }
//    
//}
