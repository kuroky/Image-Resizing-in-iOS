//
//  ImageViewController.h
//  ImageResize
//
//  Created by kuroky on 2019/5/22.
//  Copyright © 2019 Emucoo. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, ResizeType) {
    ResizeWithCoreGraphics              =           1,
    ResizeWithCoreImage                 =           2,
    ResizeWithImageIO                   =           3,
    ResizeWithUIKit                     =           4,
    ResizeWithvImage                    =           5
};

NS_ASSUME_NONNULL_BEGIN

@interface ImageViewController : UIViewController

@property (nonatomic, assign) ResizeType resizeType;

@end

NS_ASSUME_NONNULL_END
