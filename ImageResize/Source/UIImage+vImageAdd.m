//
//  UIImage+vImageAdd.m
//  ImageResize
//
//  Created by kuroky on 2019/5/22.
//  Copyright © 2019 Emucoo. All rights reserved.
//

#import "UIImage+vImageAdd.h"
#import <Accelerate/Accelerate.h>

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
    
    // define the image format
    vImage_CGImageFormat format =
    {
        .bitsPerComponent = 8,
        .bitsPerPixel = 32,
        .colorSpace = NULL,
        .bitmapInfo = kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Little,
        .version = 0,
        .decode = NULL,
        .renderingIntent = kCGRenderingIntentDefault
    };
    
    vImage_Error error;
    
    // create and initialize the source buffer
    vImage_Buffer sourceBuffer = {0};
    
    error = vImageBuffer_InitWithCGImage(&sourceBuffer, &format, NULL, imgRef, kvImageNoFlags);
    if (error != kvImageNoError) {
        return nil;
    }
    
    CGImageRelease(imgRef);
    
    // create and initialize the destination buffer
    vImage_Buffer destinationBuffer = {0};
    error = vImageBuffer_Init(&destinationBuffer, size.height, size.width, format.bitsPerPixel, kvImageNoFlags);
    if (error != kvImageNoError) {
        return nil;
    }
    
    // scale the image
    error = vImageScale_ARGB8888(&sourceBuffer, &destinationBuffer, nil, kvImageNoFlags);
    if (error != kvImageNoError) {
        return nil;
    }
    
    // create a CGImage from the destionation buffer
    CGImageRef resizedImage = vImageCreateCGImageFromBuffer(&destinationBuffer, &format, nil, nil, kvImageNoAllocate, &error);
    UIImage *image = [UIImage imageWithCGImage:resizedImage];
    CGImageRelease(resizedImage);
    
    return image;
};

@end
