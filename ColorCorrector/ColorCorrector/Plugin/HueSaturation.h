//
//  HueSaturation.h
//  ColorCorrector
//
//  Created by Joseph Slinker on 6/21/22.
//

#import <Foundation/Foundation.h>
#import <Foundation/Foundation.h>
#import <FxPlug/FxPlugSDK.h>

NS_ASSUME_NONNULL_BEGIN

@interface HueSaturation : NSObject <NSSecureCoding, NSCopying, FxCustomParameterInterpolation_v2>

@property double    hue;        // An angle in radians between 0 and 2Pi
@property double    saturation; // A value between 0 and 1

+ (instancetype)fromAPI: (id<PROAPIAccessing>)apiManager forParameter: (UInt32)parameter atTime: (CMTime)currentTime;
+ (void)setFromAPI: (id<PROAPIAccessing>)apiManager withID:(UInt32)parameterID hueRadians: (double)hueRadians saturation: (double)saturation atTime: (CMTime) currentTime;
+ (instancetype)fromPluginState: (NSData*)data;
- (instancetype)initWithHue:(double)hue saturation:(double)sat;

@end

NS_ASSUME_NONNULL_END
