//
//  HSBUtils.swift
//  ColorCorrector
//
//  Created by Joseph Slinker on 6/21/22.
//

import Foundation

func HSVToRGB(hue: Double, saturation: Double, value: Double, red: inout Double, green: inout Double, blue: inout Double) {
    let chroma = value * saturation
    let hPrime = (hue * 6) / (Double.pi * 2)
    let x = chroma * (1.0 - abs(fmod(hPrime, 2.0) - 1.0))
    if saturation == 0 {
        red = 0
        green = 0
        blue = 0
    } else {
        if ((0 <= hPrime) && (hPrime <= 1.0)) {
            red = chroma
            green = x
            blue = 0
        } else if ((1.0 <= hPrime) && (hPrime <= 2.0)) {
            red = x
            green = chroma
            blue = 0
        } else if ((2.0 <= hPrime) && (hPrime <= 3.0)) {
            red = 0.0
            green = chroma
            blue = x
        } else if ((3.0 <= hPrime) && (hPrime <= 4.0)) {
            red = 0.0
            green = x
            blue = chroma
        } else if ((4.0 <= hPrime) && (hPrime <= 5.0)) {
            red = x
            green = 0.0
            blue = chroma
        } else {
            red = chroma
            green = 0.0
            blue = x
        }
        let valChromaDiff = value - chroma
        red += valChromaDiff
        green += valChromaDiff
        blue += valChromaDiff
    }
}
