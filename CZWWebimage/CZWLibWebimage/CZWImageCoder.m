//
//  CZWImageCoder.m
//  CZWWebimage
//
//  Created by dingdang on 2019/4/22.
//  Copyright © 2019 dingdang. All rights reserved.
//

#import "CZWImageCoder.h"
#import <ImageIO/ImageIO.h>

static const NSTimeInterval kJAnimatedImageDelayTimeIntervalMinimum = 0.02;
static const NSTimeInterval kJAnimatedImageDefaultDelayTimeInterval = 0.1;

@implementation CZWImageCoder

+(instancetype)shareCoder
{
    static CZWImageCoder *_coder;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _coder = [[CZWImageCoder alloc] init];
    });
    return _coder;
}

- (JImageFormat)imageFormatWithData:(NSData *)data {
    if (!data) {
        return JImageFormatUndefined;
    }
    uint8_t c;
    [data getBytes:&c length:1];
    switch (c) {
            case 0xFF:
            return JImageFormatJPEG;
            case 0x89:
            return JImageFormatPNG;
            case 0x47:
            return JImageFormatGIF;
        default:
            return JImageFormatUndefined;
    }
}

-(UIImage *)decodeImageWithData:(NSData *)data
{
    JImageFormat format = [self imageFormatWithData:data];
    switch (format) {
            case JImageFormatJPEG:
            case JImageFormatPNG:{
                UIImage *image = [[UIImage alloc] initWithData:data];
                image.imageFormat = format;
                return image;
            }
            case JImageFormatGIF:
            return [self decodeGIFWithData:data];
        default:
            return nil;
    }
}

- (UIImage *)decodeGIFWithData:(NSData *)data {
    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
    if (!source) {
        return nil;
    }
    size_t count = CGImageSourceGetCount(source);
    UIImage *animatedImage;
    if (count <= 1) {
        animatedImage = [[UIImage alloc] initWithData:data];
        animatedImage.imageFormat = JImageFormatGIF;
    } else {
        NSInteger loopCount = 0;
        CFDictionaryRef properties = CGImageSourceCopyProperties(source, NULL);
        if (properties) {
            CFDictionaryRef gif = CFDictionaryGetValue(properties, kCGImagePropertyGIFDictionary);
            if (gif) {
                CFTypeRef loop = CFDictionaryGetValue(gif, kCGImagePropertyGIFLoopCount);
                if (loop) {
                    CFNumberGetValue(loop, kCFNumberNSIntegerType, &loopCount);
                }
            }
            CFRelease(properties);
        }
        
        NSMutableArray<NSNumber *> *delayTimeArray = [NSMutableArray array];
        NSMutableArray<UIImage *> *imageArray = [NSMutableArray array];
        NSTimeInterval duration = 0;
        
        for (size_t i = 0; i < count; i ++) {
            CGImageRef imageRef = CGImageSourceCreateImageAtIndex(source, i, NULL);
            if (!imageRef) {
                continue;
            }
            UIImage *image = [[UIImage alloc] initWithCGImage:imageRef];
            [imageArray addObject:image];
            CGImageRelease(imageRef);
            
            float delayTime = kJAnimatedImageDefaultDelayTimeInterval;
            CFDictionaryRef properties = CGImageSourceCopyPropertiesAtIndex(source, i, NULL);
            if (properties) {
                CFDictionaryRef gif = CFDictionaryGetValue(properties, kCGImagePropertyGIFDictionary);
                if (gif) {
                    CFTypeRef value = CFDictionaryGetValue(gif, kCGImagePropertyGIFUnclampedDelayTime);
                    if (!value) {
                        value = CFDictionaryGetValue(gif, kCGImagePropertyGIFDelayTime);
                    }
                    if (value) {
                        CFNumberGetValue(value, kCFNumberFloatType, &delayTime);
                        if (delayTime < ((float)kJAnimatedImageDelayTimeIntervalMinimum - FLT_EPSILON)) {
                            delayTime = kJAnimatedImageDefaultDelayTimeInterval;
                        }
                    }
                }
                CFRelease(properties);
            }
            duration += delayTime;
            [delayTimeArray addObject:@(delayTime)];
        }
        animatedImage = [[UIImage alloc] init];
        animatedImage.imageFormat = JImageFormatGIF;
        animatedImage.images = [imageArray copy];
        animatedImage.animationRepeatCount = loopCount;
        animatedImage.animationDuration = duration;
    }
    CFRelease(source);
    return animatedImage;
}

@end
