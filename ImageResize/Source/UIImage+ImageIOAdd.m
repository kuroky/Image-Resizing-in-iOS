//
//  UIImage+ImageIOAdd.m
//  ImageResize
//
//  Created by kuroky on 2019/5/22.
//  Copyright © 2019 Emucoo. All rights reserved.
//

#import "UIImage+ImageIOAdd.h"
#import <ImageIO/ImageIO.h>

@implementation UIImage (ImageIOAdd)

+ (UIImage *)imageio_resiImage:(NSURL *)url forSize:(CGSize)size {
    
    NSDictionary *dic = @{
                          (id) kCGImageSourceCreateThumbnailWithTransform: @YES,
                          (id) kCGImageSourceCreateThumbnailFromImageAlways: @YES,
                          (id) kCGImageSourceThumbnailMaxPixelSize: @(MAX(size.width, size.height))};
    CFDictionaryRef option = (__bridge CFDictionaryRef)dic;
    
    CGImageSourceRef imgSource = CGImageSourceCreateWithURL((__bridge CFURLRef)url, nil);
    CGImageRef imgRef = CGImageSourceCreateThumbnailAtIndex(imgSource, 0, option);
    UIImage *image = [UIImage imageWithCGImage:imgRef];
    CFRelease(imgSource);
    CGImageRelease(imgRef);
    return image;
};

@end
