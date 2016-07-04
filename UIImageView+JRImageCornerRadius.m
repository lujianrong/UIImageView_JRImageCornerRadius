//
//  UIImageView+JRImageCornerRadius.m
//  RoundedImage
//
//  Created by lujianrong on 16/4/27.
//  Copyright © 2016年 lujianrong. All rights reserved.
//

#import "UIImageView+JRImageCornerRadius.h"
#import <objc/runtime.h>

@interface UIImage  (cornerRadius)
@property (nonatomic, assign) BOOL    JRCornerRadius;
@end

@implementation UIImage (cornerRadius)

- (BOOL)JRCornerRadius {
    return [objc_getAssociatedObject(self, @selector(JRCornerRadius)) boolValue];
}

- (void)setJRCornerRadius:(BOOL)JRCornerRadius {
    objc_setAssociatedObject(self, @selector(JRCornerRadius), @(JRCornerRadius), OBJC_ASSOCIATION_COPY_NONATOMIC);
}
@end

@interface JRImageObserver : NSObject
@property (nonatomic, assign) UIImageView    *originImageView;
@property (nonatomic, strong) UIImage   *originImage;
@property (nonatomic, assign) CGFloat    cornerRadius;
- (instancetype)initWithImageView:(UIImageView *)imageView;
@end
@implementation JRImageObserver
- (instancetype)initWithImageView:(UIImageView *)imageView {
    if (self = [super init]) {
        self.originImageView = imageView;
        [imageView addObserver:self forKeyPath:@"image" options:NSKeyValueObservingOptionNew context:nil];
        [imageView addObserver:self forKeyPath:@"contentMode" options:NSKeyValueObservingOptionNew context:nil];
    }
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"image"]) {
        UIImage *newImage = change[@"new"];
        if (![newImage isKindOfClass:[UIImage class]])  return;
        [self updateImageView];
        if ([keyPath isEqualToString:@"contentMode"])  self.originImageView.image = self.originImage;

    }
}

- (void)updateImageView {
    self.originImage = self.originImageView.image;
    if (!self.originImage)  return;

    UIImage *image = nil;
    UIGraphicsBeginImageContextWithOptions(self.originImageView.bounds.size, NO, [UIScreen mainScreen].scale);
    CGContextRef currnetContext = UIGraphicsGetCurrentContext();
    if (currnetContext) {
        CGContextAddPath(currnetContext, [UIBezierPath bezierPathWithRoundedRect:self.originImageView.bounds cornerRadius:self.cornerRadius].CGPath);
        CGContextClip(currnetContext);
        [self.originImageView.layer renderInContext:currnetContext];
        image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    if ([image isKindOfClass:[UIImage class]]) {
        image.JRCornerRadius = YES;
        self.originImageView.image = image;
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateImageView];
        });
    }
}
@end

@implementation UIImageView (JRImageCornerRadius)

- (CGFloat)JRCornerRadius {
    return [self imageObserver].cornerRadius;
}

- (void)setJRCornerRadius:(CGFloat)JRCornerRadius {
    [self imageObserver].cornerRadius = JRCornerRadius;
}
- (JRImageObserver *)imageObserver {
    JRImageObserver *imageObserver = objc_getAssociatedObject(self, @selector(imageObserver));
    if (!imageObserver) {
        imageObserver = [[JRImageObserver alloc] initWithImageView:self];
        objc_setAssociatedObject(self, @selector(imageObserver), imageObserver, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return imageObserver;
}

@end
