//
//  UIImage+vImageAdd.m
//  ImageResize
//
//  Created by kuroky on 2019/5/22.
//  Copyright © 2019 Emucoo. All rights reserved.
//

#import "UIImage+vImageAdd.h"
#import <Accelerate/Accelerate.h>

#define onExit\
__strong void(^block)(void) __attribute__((cleanup(blockCleanUp), unused)) = ^

@implementation UIImage (vImageAdd)

+ (UIImage *)v_resiImage:(NSURL *)url forSize:(CGSize)size {
    
    // decode source image
    CGImageSourceRef imgSource = CGImageSourceCreateWithURL((__bridge CFURLRef)url, NULL);
    if (!imgSource) {
        return nil;
    }
    
    CGImageRef imgRef = CGImageSourceCreateImageAtIndex(imgSource, 0, NULL);
    CFDictionaryRef property = CGImageSourceCopyPropertiesAtIndex(imgSource, 0, NULL);
    NSDictionary *dicPro = (__bridge_transfer NSDictionary *)property;
    CGFloat imgWidth = [dicPro[(NSString *)kCGImagePropertyPixelWidth] floatValue];
    CGFloat imgHeight = [dicPro[(NSString *)kCGImagePropertyPixelHeight] floatValue];
    
    CFRelease(imgSource);
    if (!imgRef || !imgWidth || !imgHeight) {
        return nil;
    }
    
    // define the image format ARGB8888
    vImage_CGImageFormat format =
    {
        .bitsPerComponent = 8, // 8位
        .bitsPerPixel = 32, // ARGB4通道, 4 * 8
        .colorSpace = NULL, // 默认为sRGB
        .bitmapInfo = kCGImageAlphaFirst | kCGBitmapByteOrderDefault, // 表示ARGB
        .version = 0, // 默认0
        .decode = NULL, // 和'CGImageCreate'的decode参数一样，可以用来做色彩范围映射，null就是[0, 1.0]
        .renderingIntent = kCGRenderingIntentDefault // 和'CGImageCreate'的intent参数一样，当色彩空间超过后如何处理
    };
    
    vImage_Error error;
    
    
    // create and initialize the source buffer
    vImage_Buffer sourceBuffer = {0}, destinationBuffer = {0};
    
    error = vImageBuffer_InitWithCGImage(&sourceBuffer, &format, NULL, imgRef, kvImageNoFlags);
    if (error != kvImageNoError) {
        return nil;
    }
    CGImageRelease(imgRef);
    
    // create and initialize the destination buffer
    destinationBuffer.width = size.width;
    destinationBuffer.height = size.height;
    destinationBuffer.rowBytes = (destinationBuffer.width * 4 + (64 - 1)) / 64 * 64;
    destinationBuffer.data = malloc(destinationBuffer.rowBytes * destinationBuffer.height);
    if (!destinationBuffer.data) {
        return nil;
    }
    /*
    error = vImageBuffer_Init(&destinationBuffer, size.height, size.width, format.bitsPerPixel, kvImageNoFlags);
    if (error != kvImageNoError) {
        return nil;
    }
    */
    // scale the image
    error = vImageScale_ARGB8888(&sourceBuffer, &destinationBuffer, NULL, kvImageHighQualityResampling);
    if (error != kvImageNoError) {
        return nil;
    }
    
    // create a CGImage from the destionation buffer
    CGImageRef resizedImage = vImageCreateCGImageFromBuffer(&destinationBuffer, &format, NULL, NULL, kvImageNoFlags, &error);
    UIImage *image = [UIImage imageWithCGImage:resizedImage];
    free(sourceBuffer.data);
    CGImageRelease(resizedImage);
    return image;
};

@end
