//
//  HueSaturation.m
//  ColorCorrector
//
//  Created by Joseph Slinker on 6/21/22.
//

#import "HueSaturation.h"

static NSString*    kKey_Hue        = @"Hue";
static NSString*    kKey_Saturation = @"Saturation";

@implementation HueSaturation

- (instancetype)initWithHue:(double)hue
                 saturation:(double)sat
{
    self = [super init];
    
    if (self != nil)
    {
        self.hue = hue;
        self.saturation = sat;
    }
    
    return self;
}

+ (BOOL)supportsSecureCoding
{
    return YES;
}

+ (instancetype)fromAPI: (id<PROAPIAccessing>)apiManager forParameter: (UInt32)parameter atTime: (CMTime)currentTime {
    // Retrieve the hue/saturation parameter
    id<FxParameterRetrievalAPI_v6> paramAPI = [apiManager apiForProtocol:@protocol(FxParameterRetrievalAPI_v6)];

    HueSaturation* hueSat  = nil;
    [paramAPI getCustomParameterValue:&hueSat fromParameter:parameter atTime:currentTime];
    return hueSat;
}

+ (void)setFromAPI: (id<PROAPIAccessing>)apiManager withID:(UInt32)parameterID hueRadians: (double)hueRadians saturation: (double)saturation atTime: (CMTime) currentTime {
    id<FxParameterSettingAPI_v5> paramAPI = [apiManager apiForProtocol:@protocol(FxParameterSettingAPI_v5)];
    HueSaturation* colorData = [[[HueSaturation alloc] initWithHue:hueRadians saturation:saturation]
                                       autorelease];
    [paramAPI setCustomParameterValue:colorData toParameter:parameterID atTime:currentTime];
}

+ (instancetype)fromPluginState: (NSData*)data {
    HueSaturation* hsv;
    [data getBytes:&hsv length:sizeof(hsv)];
    
    double hue = 0.0;
    double sat = 0.0;
    [data getBytes:&hue length:sizeof(hue)];
    
    NSRange satRange = NSMakeRange(sizeof(hue), sizeof(sat));
    [data getBytes:&sat range:satRange];
    
//    NSRange valueRange  = NSMakeRange(sizeof(hue) + sizeof(sat), sizeof(val));
//    [pluginState getBytes:&val
//                    range:valueRange];
    
    return [[HueSaturation alloc] initWithHue:hue saturation:sat];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    
    if (self != nil)
    {
        _hue = [aDecoder decodeDoubleForKey:kKey_Hue];
        _saturation = [aDecoder decodeDoubleForKey:kKey_Saturation];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeDouble:_hue
                  forKey:kKey_Hue];
    [aCoder encodeDouble:_saturation
                  forKey:kKey_Saturation];
}

- (instancetype)copyWithZone:(NSZone *)zone
{
    HueSaturation* newInstance = [[HueSaturation alloc] initWithHue:self.hue saturation:self.saturation];
    return newInstance;
}

- (NSObject<NSSecureCoding, NSCopying>*)interpolateBetween:(NSObject<NSSecureCoding, NSCopying>*)rightValue
                                                withWeight:(float)weight
{
    HueSaturation*    rhs = (HueSaturation*)rightValue;
    double            newHue  = fmod(self.hue + (rhs.hue - self.hue) * weight, M_PI * 2.0);
    double            newSat  = self.saturation + (rhs.saturation - self.saturation) * weight;
    HueSaturation*    result  = [[HueSaturation alloc] initWithHue:newHue
                                                            saturation:newSat];
    return [result autorelease];
}

- (BOOL)isEqual:(NSObject<NSSecureCoding, NSCopying>*)object
{
    HueSaturation*    rhs = (HueSaturation*)object;
    if ((self.hue == rhs.hue) && (self.saturation == rhs.saturation))
    {
        return YES;
    }
    
    return NO;
}

@end
