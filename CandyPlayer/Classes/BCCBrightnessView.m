//
//  BCCBrightnessView.m
//  YingShengEnterpriseEdition
//
//  Created by baiwhte on 2017/4/10.
//  Copyright © 2017年 baiwhte. All rights reserved.
//

#import "BCCBrightnessView.h"

@interface BCCBrightnessView ()

/**
 *  亮度图标
 */
@property (nonatomic, strong) UIImageView *iconImageView;

/**
 *  标题
 */
@property (nonatomic, strong) UILabel *titleLabel;

/**
 *  亮度长度
 */
@property (nonatomic, strong) UIView *longView;

/**
 *  亮度提示数组
 */
@property (nonatomic, strong) NSMutableArray *tipArray;

@end

@implementation BCCBrightnessView

+ (instancetype)sharedBrightnessView {
    static BCCBrightnessView *instance;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        instance = [[BCCBrightnessView alloc] init];
        //        [[UIApplication sharedApplication].keyWindow addSubview:instance];
    });
    
    return instance;
}

- (instancetype)init {
    self = [super init];
    
    if (self) {
        self.frame = CGRectMake(0, 0, 155, 155);
        self.center = CGPointMake([UIScreen mainScreen].bounds.size.width * 0.5, [UIScreen mainScreen].bounds.size.height * 0.5);
        
        self.layer.cornerRadius  = 10;
        self.layer.masksToBounds = YES;
        
        // 使用UIToolbar实现毛玻璃效果，简单粗暴，支持iOS7+
        //        UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:self.bounds];
        //        toolbar.alpha = 0.97;
        //        [self addSubview:toolbar];
        
        UIView *backgroundView = [[UIView alloc] initWithFrame:self.bounds];
        backgroundView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.4];
        [self addSubview:backgroundView];
        
        self.iconImageView = ({
            UIImageView *iconImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 79, 76)];
            iconImageView.center = CGPointMake(self.bounds.size.width * 0.5, self.bounds.size.height * 0.5);
            iconImageView.image = [UIImage imageNamed:@"brightness"];
            [self addSubview:iconImageView];
            iconImageView;
        });
        
        self.titleLabel = ({
            UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 5, self.bounds.size.width, 30)];
            titleLabel.font = [UIFont boldSystemFontOfSize:16];
            //            titleLabel.textColor = [UIColor colorWithRed:0.25f green:0.22f blue:0.21f alpha:1.00f];
            titleLabel.textColor = [UIColor whiteColor];
            titleLabel.textAlignment = NSTextAlignmentCenter;
            titleLabel.text = @"亮度";
            [self addSubview:titleLabel];
            titleLabel;
        });
        
        self.longView = ({
            UIView *longView = [[UIView alloc] initWithFrame:CGRectMake(13, 132, self.bounds.size.width - 26, 7)];
            longView.backgroundColor = [UIColor colorWithRed:0.25f green:0.22f blue:0.21f alpha:1.00f];
            [self addSubview:longView];
            longView;
        });
        
        self.alpha = 0.0;
        [self createTips];
        
        [[UIScreen mainScreen] addObserver:self forKeyPath:@"brightness" options:NSKeyValueObservingOptionNew context:NULL];
        //        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationDidChange:) name:UIDeviceOrientationDidChangeNotification object:nil];
    }
    
    return self;
}

// 创建 Tips
- (void)createTips {
    self.tipArray = [NSMutableArray arrayWithCapacity:16];
    
    CGFloat tipW = (self.longView.bounds.size.width - 17) / 16;
    CGFloat tipH = 5;
    CGFloat tipY = 1;
    
    for (int i = 0; i < 16; i++) {
        CGFloat tipX = i * (tipW + 1) + 1;
        UIImageView *image = [[UIImageView alloc] init];
        image.backgroundColor = [UIColor whiteColor];
        image.frame = CGRectMake(tipX, tipY, tipW, tipH);
        [self.longView addSubview:image];
        [self.tipArray addObject:image];
    }
    
    [self updateLongView:[UIScreen mainScreen].brightness];
}

#pragma mark - 屏幕亮度 KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    self.alpha = 1.0;
    [[UIApplication sharedApplication].keyWindow addSubview:self];
    [self performSelector:@selector(hide) withObject:nil afterDelay:1.0];
    
    CGFloat brightness = [change[@"new"] floatValue];
    [self updateLongView:brightness];
}

#pragma mark - Notifcation

- (void)orientationDidChange:(NSNotification *)notif {
    self.orientation = [UIDevice currentDevice].orientation;
    
    if (self.orientation == UIDeviceOrientationPortrait ||
        self.orientation == UIDeviceOrientationLandscapeLeft ||
        self.orientation == UIDeviceOrientationLandscapeRight) {
        [self setNeedsLayout];
        [self layoutIfNeeded];
    }
}

#pragma mark - Update View

- (void)updateLongView:(CGFloat)brightness {
    CGFloat stage = 1 / 16.0;
    NSInteger level = brightness / stage;
    
    for (int i = 0; i < self.tipArray.count; i++) {
        UIImageView *img = self.tipArray[i];
        
        if (i <= level - 1) {
            img.hidden = NO;
        } else {
            img.hidden = YES;
        }
    }
}

- (void)hide {
    __weak __typeof(self) weakSelf = self;
    [UIView animateWithDuration:1.0 animations:^{
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        strongSelf.alpha = 0.0;
        [strongSelf removeFromSuperview];
    }];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (self.orientation == UIDeviceOrientationLandscapeLeft) {
        self.transform = CGAffineTransformMakeRotation(-M_PI_2);
    } else if (self.orientation == UIDeviceOrientationLandscapeRight) {
        self.transform = CGAffineTransformMakeRotation(M_PI_2);
    } else {
        self.transform = CGAffineTransformIdentity;
    }
}

- (void)setOrientation:(UIDeviceOrientation)orientation {
    _orientation = orientation;
    
    if (self.orientation == UIDeviceOrientationPortrait ||
        self.orientation == UIDeviceOrientationLandscapeLeft ||
        self.orientation == UIDeviceOrientationLandscapeRight) {
        [self setNeedsLayout];
        [self layoutIfNeeded];
    }
}

- (void)dealloc {
    [[UIScreen mainScreen] removeObserver:self forKeyPath:@"brightness"];
    //    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end

