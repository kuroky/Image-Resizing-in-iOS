//
//  UIImage+CoreImageAdd.m
//  ImageResize
//
//  Created by kuroky on 2019/5/22.
//  Copyright © 2019 Emucoo. All rights reserved.
//

#import "UIImage+CoreImageAdd.h"
#import <CoreImage/CoreImage.h>



@implementation UIImage (CoreImageAdd)

+ (CIContext *)context {
    static dispatch_once_t onceToken;
    static CIContext *context = nil;
    dispatch_once(&onceToken, ^{
        context = [[CIContext alloc] initWithOptions:@{kCIContextUseSoftwareRenderer: @(NO)}];
    });
    return context;
}

+ (UIImage *)ci_resiImage:(NSURL *)url forSize:(CGSize)size {
    CGImageSourceRef imgSource = CGImageSourceCreateWithURL((__bridge CFURLRef)url, NULL);
    
    CFDictionaryRef propety = CGImageSourceCopyPropertiesAtIndex(imgSource, 0, NULL);
    NSDictionary *dicPro = (__bridge_transfer NSDictionary *)propety;
    CGFloat imgWidth = [dicPro[(NSString *)kCGImagePropertyPixelWidth] floatValue];
    CGFloat imgHeight = [dicPro[(NSString *)kCGImagePropertyPixelHeight] floatValue];
    
    CGFloat scale = MAX(size.width, size.height) / MAX(imgWidth, imgHeight);
    if (scale < 0) {
        return nil;
    }
    
    CGFloat ratio = imgWidth / imgHeight;
    if (ratio < 0) {
        return nil;
    }
    
    return [UIImage resizedImage:url scale:scale aspectRatio:ratio];
}

+ (UIImage *)resizedImage:(NSURL *)url scale:(CGFloat)scale aspectRatio:(CGFloat)ratio {
    CIImage *image = [CIImage imageWithContentsOfURL:url];
    
    CIFilter *filter = [CIFilter filterWithName:@"CILanczosScaleTransform"];
    
    [filter setValue:image forKey:kCIInputImageKey];
    [filter setValue:@(scale) forKey:kCIInputScaleKey];
    [filter setValue:@(ratio) forKey:kCIInputAspectRatioKey];
    
    CIImage *outputCIImage = filter.outputImage;
    CGImageRef outputCGImage = [[self context] createCGImage:outputCIImage fromRect:outputCIImage.extent];
    UIImage *outimage = [UIImage imageWithCGImage:outputCGImage];
    CGImageRelease(outputCGImage);
    return outimage;
}

@end
