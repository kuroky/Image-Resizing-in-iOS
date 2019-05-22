//
//  UIImage+UIKitAdd.m
//  ImageResize
//
//  Created by kuroky on 2019/5/22.
//  Copyright © 2019 Emucoo. All rights reserved.
//

#import "UIImage+UIKitAdd.h"

@implementation UIImage (UIKitAdd)

+ (UIImage *)uikit_resiImage:(NSURL *)url forSize:(CGSize)size {
    
    UIImage *image = [UIImage imageWithContentsOfFile:url.path];
    
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:size];
    return [renderer imageWithActions:^(UIGraphicsImageRendererContext * _Nonnull rendererContext) {
        [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    }];
}

@end
