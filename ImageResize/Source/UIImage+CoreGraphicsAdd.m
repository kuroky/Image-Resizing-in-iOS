//
//  UIImage+CoreGraphicsAdd.m
//  ImageResize
//
//  Created by kuroky on 2019/5/22.
//  Copyright © 2019 Emucoo. All rights reserved.
//

#import "UIImage+CoreGraphicsAdd.h"
#import <CoreGraphics/CoreGraphics.h>

@implementation UIImage (CoreGraphicsAdd)

+ (UIImage *)cg_resizedImage:(NSURL *)url forSize:(CGSize)size {
    
    if (CGSizeEqualToSize(size, CGSizeZero)) {
        return nil;
    }
    
    CGImageSourceRef imgSource = CGImageSourceCreateWithURL((__bridge CFURLRef)url, NULL);
    if (!imgSource) {
        return nil;
    }
    
    CGImageRef oriRef = CGImageSourceCreateImageAtIndex(imgSource, 0, nil);
    CFRelease(imgSource);
    
    CGColorSpaceRef rgbColorSpace = CGImageGetColorSpace(oriRef);
    if (!rgbColorSpace) {
        rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    size_t bitsPerComponet = CGImageGetBitsPerComponent(oriRef);
    size_t bytesPerRow = CGImageGetBytesPerRow(oriRef);
    CGBitmapInfo bitInfo = CGImageGetBitmapInfo(oriRef);
    
    CGContextRef context = CGBitmapContextCreate(NULL,
                                                 size.width,
                                                 size.height,
                                                 bitsPerComponet,
                                                 bytesPerRow,
                                                 rgbColorSpace,
                                                 bitInfo);
    
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    CGContextDrawImage(context, CGRectMake(0, 0, size.width, size.height), oriRef);
    CGImageRef imgRef = CGBitmapContextCreateImage(context);
    UIImage *image = [UIImage imageWithCGImage:imgRef];
    CGContextRelease(context);
    CGImageRelease(imgRef);
    return image;
}

@end
