//
//  UIImage+ImageIOAdd.m
//  ImageResize
//
//  Created by kuroky on 2019/5/22.
//  Copyright © 2019 Emucoo. All rights reserved.
//

#import "UIImage+ImageIOAdd.h"
#import <ImageIO/ImageIO.h>
#import <MobileCoreServices/MobileCoreServices.h>

@implementation UIImage (ImageIOAdd)

+ (UIImage *)imageio_resiImage:(NSURL *)url forSize:(CGSize)size {
    
    CGImageSourceRef imgSource = CGImageSourceCreateWithURL((__bridge CFURLRef)url, NULL);
    if (!imgSource) {
        return nil;
    }
    
    NSDictionary *dic = @{
                          (NSString *) kCGImageSourceCreateThumbnailWithTransform: @YES,
                          (NSString *) kCGImageSourceCreateThumbnailFromImageAlways: @YES,
                          (NSString *) kCGImageSourceThumbnailMaxPixelSize: @(MAX(size.width, size.height))};
    CFDictionaryRef option = (__bridge CFDictionaryRef)dic;
    
    CGImageRef imgRef = CGImageSourceCreateThumbnailAtIndex(imgSource, 0, option);
    UIImage *image = [UIImage imageWithCGImage:imgRef];
    CFRelease(imgSource);
    CGImageRelease(imgRef);
    return image;
};

+ (UIImage *)imageio_resiImageWithHintingAndSubsampling:(NSURL *)url forSize:(CGSize)size {
    
    CGImageSourceRef imgSource = CGImageSourceCreateWithURL((__bridge CFURLRef)url, NULL);
    if (!imgSource) {
        return nil;
    }
    
    CFDictionaryRef properties = CGImageSourceCopyPropertiesAtIndex(imgSource, 0, NULL);
    NSDictionary *dicProper = (NSDictionary *)CFBridgingRelease(properties);
    CGFloat imgWidth = [dicProper[(NSString *)kCGImagePropertyPixelWidth] floatValue];
    CGFloat imgHeight = [dicProper[(NSString *)kCGImagePropertyPixelHeight] floatValue];

    NSDictionary *dic = @{
                          (NSString *) kCGImageSourceCreateThumbnailWithTransform: @YES,
                          (NSString *) kCGImageSourceCreateThumbnailFromImageAlways: @YES,
                          (NSString *) kCGImageSourceThumbnailMaxPixelSize: @(MAX(size.width, size.height))};
    NSMutableDictionary *muDic = [NSMutableDictionary dictionaryWithDictionary:dic];
    
    NSString *UTI = (__bridge_transfer NSString *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)url.pathExtension, kUTTypeImage);
    
    if ([UTI isEqualToString:(NSString *)kUTTypeJPEG] || [UTI isEqualToString:(NSString *)kUTTypeTIFF] || [UTI isEqualToString:(NSString *)kUTTypePNG] || [UTI hasPrefix:@"public.heif"]) {
        CGFloat scale = MIN(imgWidth / size.width, imgHeight / size.height);
        if (scale < 2.0) {
            muDic[(NSString *)kCGImageSourceSubsampleFactor] = @(2.0);
        }
        else if (scale > 2.0 && scale < 4.0) {
            muDic[(NSString *)kCGImageSourceSubsampleFactor] = @(4.0);
        }
        else if (scale > 4.0) {
            muDic[(NSString *)kCGImageSourceSubsampleFactor] = @(8.0);
        }
    }
    CFDictionaryRef option = (__bridge CFDictionaryRef)muDic;
    CGImageRef imgRef = CGImageSourceCreateThumbnailAtIndex(imgSource, 0, option);
    UIImage *image = [UIImage imageWithCGImage:imgRef];
    CFRelease(imgSource);
    CGImageRelease(imgRef);
    return image;
}

@end
