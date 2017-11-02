//
//  BCCSettingView.m
//
//
//  Created by 陈修武 on 2017/10/9.
//  Copyright © 2017年 Andy. All rights reserved.
//

#import "BCCSettingView.h"
#import "BCCControlView.h"
#import "UIImage+BCCAdd.h"

//third open source lib
#import <ReactiveObjC/ReactiveObjC.h>

@interface BCCSettingView () <UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIImageView *closeImageView;
@property (nonatomic, strong) UIImageView *luminanceImageView;
@property (nonatomic, strong) UIImageView *volumeImageView;
@property (nonatomic, strong) UISlider *luminanceControl;
@property (nonatomic, strong) UISlider *volumeControl;

@end

@implementation BCCSettingView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.7];
        
        [self addSubview:self.closeImageView];
        [self addSubview:self.luminanceImageView];
        [self addSubview:self.volumeImageView];
        [self addSubview:self.luminanceControl];
        [self addSubview:self.volumeControl];

        [self addSliderActions];

        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]  initWithTarget:self action:@selector(onTap:)];
        tap.delegate = self;
        tap.numberOfTapsRequired = 1;
        tap.numberOfTouchesRequired = 1;
        [self addGestureRecognizer:tap];
    }
    
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat width = self.bounds.size.width;
    CGFloat height = self.bounds.size.height;
    
    self.closeImageView.frame = CGRectMake(60, 25, self.closeImageView.frame.size.width, self.closeImageView.frame.size.height);
    
    self.luminanceImageView.frame = CGRectMake(width/2 - 200/2 - 10 - self.luminanceImageView.frame.size.width,
                                               height/2 - self.luminanceImageView.frame.size.height - 20,
                                               self.luminanceImageView.frame.size.width,
                                               self.luminanceImageView.frame.size.height);
    
    self.luminanceControl.frame = CGRectMake(CGRectGetMaxX(self.luminanceImageView.frame) + 10,
                                             self.luminanceImageView.frame.origin.y,
                                             200,
                                             self.luminanceImageView.frame.size.height);
    
    self.volumeImageView.frame = CGRectMake(width/2 - 200/2 - 10 - self.luminanceImageView.frame.size.width,
                                            height/2 + 20,
                                            self.luminanceImageView.frame.size.width,
                                            self.luminanceImageView.frame.size.height);
    
    self.volumeControl.frame = CGRectMake(CGRectGetMaxX(self.volumeImageView.frame) + 10,
                                          self.volumeImageView.frame.origin.y,
                                          200,
                                          self.volumeImageView.frame.size.height);
}

- (void)addSliderActions {
    [[[self.luminanceControl rac_newValueChannelWithNilValue:@0] startWith:@([UIScreen mainScreen].brightness)]
     subscribeNext:^(NSNumber * _Nullable x) {
         [UIScreen mainScreen].brightness = x.floatValue;
     }];
    @weakify(self)
    [[[self.volumeControl rac_newValueChannelWithNilValue:@0] startWith:@0]
     subscribeNext:^(NSNumber * _Nullable x) {
         @strongify(self)
         if ([self.superview isKindOfClass:BCCControlView.class]) {
             BCCControlView *controlView = (BCCControlView *)self.superview;
//             [controlView setVolume:x.floatValue];
         }
     }];
}

#pragma mark - selector

- (void)onTap:(UITapGestureRecognizer *)ges {
    self.transform = CGAffineTransformIdentity;
    [UIView animateWithDuration:.3 animations:^{
        self.transform = CGAffineTransformScale(CGAffineTransformIdentity, .1, .1);
    } completion:^(BOOL finished) {
        self.transform = CGAffineTransformIdentity;
        [self removeFromSuperview];
    }];
}


#pragma mark -

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    CGPoint p = [touch locationInView:self];
    if (CGRectContainsPoint(CGRectMake(self.luminanceImageView.frame.origin.x,
                                       self.luminanceImageView.frame.origin.y - 20,
                                       self.luminanceImageView.frame.size.width + 10 + self.volumeControl.frame.size.width + 20,
                                       self.luminanceImageView.frame.size.height + 40 + self.volumeControl.frame.size.height + 20 + 20), p)) {
        return NO;
    }
    return YES;
}

#pragma mark - getters setters

- (UIImageView *)closeImageView {
    if (_closeImageView == nil) {
        _closeImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"coursePlayerCloseBtn"]];
        _closeImageView.userInteractionEnabled = NO;
    }
    return _closeImageView;
}

- (UIImageView *)luminanceImageView {
    if (_luminanceImageView == nil) {
        _luminanceImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"coursePlayerLightnesscourseBtn"]];
    }
    return _luminanceImageView;
}

- (UIImageView *)volumeImageView {
    if (_volumeImageView == nil) {
        _volumeImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"coursePlayerVolumeBtn"]];
    }
    return _volumeImageView;
}

- (UISlider *)luminanceControl {
    if (_luminanceControl == nil) {
        _luminanceControl = [[UISlider alloc] init];
        _luminanceControl.maximumTrackTintColor = [UIColor colorWithWhite:0.8 alpha:1];
        _luminanceControl.minimumTrackTintColor = [UIColor colorWithWhite:0.8 alpha:1];
        _luminanceControl.minimumValue = 0.1;
        _luminanceControl.maximumValue = 1;
        _luminanceControl.value = [UIScreen mainScreen].brightness;
        UIImage *thumbImage = [UIImage bcc_imageWithColor:[UIColor whiteColor]
                                                    size:CGSizeMake(16, 16)];
        [_luminanceControl setThumbImage:[thumbImage bcc_roundedCornerWithCornerRadius:8]
                                forState:UIControlStateNormal];
    }
    return _luminanceControl;
}

- (UISlider *)volumeControl {
    if (_volumeControl == nil) {
        _volumeControl = [[UISlider alloc] init];
        _volumeControl.maximumTrackTintColor = [UIColor colorWithWhite:0.8 alpha:1];
        _volumeControl.minimumTrackTintColor = [UIColor colorWithWhite:0.8 alpha:1];
        _volumeControl.minimumValue = 0;
        _volumeControl.maximumValue = 1;
        UIImage *thumbImage = [UIImage bcc_imageWithColor:[UIColor whiteColor]
                                                    size:CGSizeMake(16, 16)];
        [_volumeControl setThumbImage:[thumbImage bcc_roundedCornerWithCornerRadius:8]
                             forState:UIControlStateNormal];
    }
    return _volumeControl;
}

@end
