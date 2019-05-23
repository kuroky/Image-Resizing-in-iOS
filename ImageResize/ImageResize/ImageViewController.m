//
//  ImageViewController.m
//  ImageResize
//
//  Created by kuroky on 2019/5/22.
//  Copyright © 2019 Emucoo. All rights reserved.
//

#import "ImageViewController.h"
#import "UIImage+CoreGraphicsAdd.h"
#import "UIImage+CoreImageAdd.h"
#import "UIImage+UIKitAdd.h"
#import "UIImage+ImageIOAdd.h"
#import "UIImage+vImageAdd.h"

static NSInteger const  kTotalCount     =   20;

@interface ImageViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIButton *clickButton;
@property (nonatomic, strong) NSURL *imgUrl;
@property (nonatomic, assign) CGSize size;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityView;

@end

@implementation ImageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationItem.title = @"Image";
    
    [self.clickButton setTitle:@"Resize" forState:UIControlStateNormal];
    [self.clickButton setTitle:@"Resizing" forState:UIControlStateSelected];
    
    self.activityView.hidden = YES;
    self.imgUrl = [[NSBundle mainBundle] URLForResource:@"VIIRS_3Feb2012_lrg" withExtension:@"jpg"];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    CGFloat scale = UIScreen.mainScreen.scale;
    CGAffineTransform transform = CGAffineTransformMakeScale(scale, scale);
    self.size = CGSizeApplyAffineTransform(self.imageView.bounds.size, transform);
}

- (IBAction)clickResize:(UIButton *)sender {
    sender.selected = YES;
    sender.userInteractionEnabled = NO;
    self.imageView.image = nil;
    self.activityView.hidden = NO;
    [self.activityView startAnimating];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        CFTimeInterval start = CACurrentMediaTime();
        UIImage *image = [self resizeImage];
        dispatch_async(dispatch_get_main_queue(), ^{
            CGFloat duration = 1.0;
            [UIView transitionWithView:self.imageView duration:duration options:UIViewAnimationCurveEaseOut|UIViewAnimationOptionTransitionCrossDissolve
                            animations:^{
                                self.imageView.image = image;
                            }
                            completion:^(BOOL finished) {
                                [self.activityView stopAnimating];
                                self.activityView.hidden = YES;
                                sender.selected = NO;
                                sender.userInteractionEnabled = YES;
                                CFTimeInterval end = CACurrentMediaTime();
                                NSLog(@"%@ time: %.2fs", [self resizeMethod], end - start - duration);
                            }];
        });
    });
}

- (IBAction)clickTest:(UIButton *)sender {
    sender.userInteractionEnabled = NO;
    [sender setTitle:@"Testing..." forState:UIControlStateNormal];
    
    self.activityView.hidden = NO;
    [self.activityView startAnimating];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        CFTimeInterval start = CACurrentMediaTime();
        for (NSInteger i = 0; i < kTotalCount; i++) {
            [self resizeImage];
        }
        
        CFTimeInterval end = CACurrentMediaTime();
        dispatch_async(dispatch_get_main_queue(), ^{
            sender.userInteractionEnabled = YES;
            [sender setTitle:@"DoTest" forState:UIControlStateNormal];
             NSLog(@"test time: %.2fs", (end - start) / kTotalCount);
            
            self.activityView.hidden = YES;
            [self.activityView stopAnimating];
        });
    });
}

- (UIImage *)resizeImage {
    if (self.resizeType == ResizeWithCoreGraphics) {
        return [UIImage cg_resizedImage:self.imgUrl forSize:self.size];
    }
    else if (self.resizeType == ResizeWithCoreImage) {
        return [UIImage ci_resiImage:self.imgUrl forSize:self.size];
    }
    else if (self.resizeType == ResizeWithUIKit) {
        return [UIImage uikit_resiImage:self.imgUrl forSize:self.size];
    }
    else if (self.resizeType == ResizeWithImageIO) {
        return [UIImage imageio_resiImage:self.imgUrl forSize:self.size];
    }
    else if (self.resizeType == ResizeWithImageIO1) {
        return [UIImage imageio_resiImageWithHintingAndSubsampling:self.imgUrl forSize:self.size];
    }
    else if (self.resizeType == ResizeWithvImage) {
        return [UIImage v_resiImage:self.imgUrl forSize:self.size];
    }
    return nil;
}

- (NSString *)resizeMethod {
    if (self.resizeType == ResizeWithCoreGraphics) {
        return @"Core Graphics";
    }
    else if (self.resizeType == ResizeWithCoreImage) {
        return @"CoreImage";
    }
    else if (self.resizeType == ResizeWithImageIO) {
        return @"ImageIO";
    }
    else if (self.resizeType == ResizeWithImageIO1) {
        return @"ImageIO1";
    }
    else if (self.resizeType == ResizeWithUIKit) {
        return @"UIKit";
    }
    else if (self.resizeType == ResizeWithvImage) {
        return @"vImage";
    }
    return nil;
}

@end
