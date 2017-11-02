//
//  BCCBottomView.m
//  CandyPlayer
//
//  Created by 陈修武 on 2017/9/25.
//  Copyright © 2017年 baiwhte. All rights reserved.
//

#import "BCCBottomView.h"
#import "UIImage+BCCAdd.h"
#import <ReactiveObjC/ReactiveObjC.h>

@interface BCCBottomView()

/*! 播放与暂停按钮  */
@property (nonatomic, strong) UIButton *playbackButton;
/*! 当前视频播放时间  */
@property (nonatomic, strong) UILabel *currentLabel;
/*! 当前视频总时间  */
@property (nonatomic, strong) UILabel *durationLabel;
/*! 当前视频播放进度条  */
@property (nonatomic, strong) UISlider *moveSlider;
/*! 当前视频缓冲进度条  */
@property (nonatomic, strong) UIProgressView *progressView;
/*! 全屏与非全屏按钮  */
@property (nonatomic, strong) UIButton *screenButton;
/*! 设置播放速率按钮  */
@property (nonatomic, strong) UIButton *rateButton;

@property (nonatomic, assign) BOOL ignoreCurrentValue;

@property (nonatomic, strong) RACSequence    *rateSignal;
@property (nonatomic, strong) RACSequence    *tailSignal;

@end

@implementation BCCBottomView

- (void)dealloc {
    NSLog(@"release");
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self initialize];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGSize size = self.bounds.size;
    if (CGSizeEqualToSize(size, CGSizeZero)) { return; }
    
    CGFloat height = size.height;
    
    self.playbackButton.frame = CGRectMake(10,
                                           0,
                                           30,
                                           height);
    
    [self.currentLabel sizeToFit];
    self.currentLabel.frame = CGRectMake(CGRectGetMaxX(self.playbackButton.frame) + 10,
                                         height/2 - 20/2,
                                         self.currentLabel.frame.size.width + 2,
                                         20);
    
    self.screenButton.frame = CGRectMake(size.width - 10 - 30,
                                         0,
                                         30,
                                         height);
    
    CGFloat durationTimeLabelRight = self.screenButton.frame.origin.x - 10;
    
    
    [self.durationLabel sizeToFit];
    self.durationLabel.frame = CGRectMake(durationTimeLabelRight - self.durationLabel.frame.size.width,
                                          height/2 - self.durationLabel.frame.size.height/2,
                                          self.durationLabel.frame.size.width + 2,
                                          self.durationLabel.frame.size.height);
    
    self.moveSlider.frame = CGRectMake(CGRectGetMaxX(self.currentLabel.frame) + 10,
                                       0,
                                       self.durationLabel.frame.origin.x - 10 - (CGRectGetMaxX(self.currentLabel.frame) + 10),
                                       height);
    //    self.progressView.frame = CGRectMake(CGRectGetMinX(self.moveSlider.frame), 0,
    //                                         CGRectGetWidth(self.moveSlider.frame), height);
    //    self.progressView.center = CGPointMake(self.moveSlider.center.x, self.moveSlider.center.y);
}

- (void)initialize {
    self.rateSignal = [@[@(.5), @(1.0), @(1.25), @(1.5), @(1.75), @(2.0)] rac_sequence];
    self.tailSignal = self.rateSignal.tail;
    [self addSubview:self.playbackButton];
    [self addSubview:self.currentLabel];
    [self addSubview:self.moveSlider];
//    [self addSubview:self.progressView];
    [self addSubview:self.durationLabel];
//    [self addSubview:self.rateButton];
    [self addSubview:self.screenButton];
    
    RAC(self.playbackButton, selected) = RACObserve(self, isPlayback);
    RAC(self.screenButton, selected) = RACObserve(self, fullScreen);
    
    NSString * (^map)(NSNumber *) = ^(NSNumber *value) {
        NSString *hhmmss = nil;
        NSInteger seconds = value.integerValue;
        if (seconds < 0) {
            return @"00:00:00";
        }
        int h = (int)round((seconds % 86400) / 3600);
        int m = (int)round((seconds % 3600) / 60);
        int s = (int)round(seconds % 60);
        
        hhmmss = [NSString stringWithFormat:@"%02d:%02d:%02d", h, m, s];
        return hhmmss;
    };
    RACSignal *currentTimeSignal = RACObserve(self, currentTime);
    RACSignal *durationSignal = RACObserve(self, duration);
    RAC(self.currentLabel, text)  = [currentTimeSignal map:map];
    RAC(self.durationLabel, text) = [durationSignal map:map];
    
    @weakify(self)
    
    [[[RACSignal combineLatest:@[currentTimeSignal,
                                durationSignal]]
      filter:^BOOL(RACTuple * _Nullable x) {
          return !self.ignoreCurrentValue;
      }]
     subscribeNext:^(RACTuple * tuple) {
         @strongify(self)
         Float64 duration = [tuple.second doubleValue];
         if (duration < 1) {
             return ;
         }
         Float64 current = [tuple.first doubleValue];
         self.moveSlider.value = (float)(current / duration);
    }];
    
    [[self.playbackButton rac_signalForControlEvents:UIControlEventTouchUpInside]
     subscribeNext:^(__kindof UIControl * _Nullable x) {
         @strongify(self)
         self.isPlayback = !self.isPlayback;
     }];
    [[self.screenButton rac_signalForControlEvents:UIControlEventTouchUpInside]
     subscribeNext:^(__kindof UIControl * _Nullable x) {
         @strongify(self)
         self.fullScreen = !self.fullScreen;
     }];
    
    [[self.moveSlider rac_signalForControlEvents:UIControlEventTouchDown]
     subscribeNext:^(__kindof UIControl * _Nullable x) {
         @strongify(self)
         self.ignoreCurrentValue = YES;
     }];
    
    [[self.moveSlider rac_signalForControlEvents:UIControlEventTouchUpOutside | UIControlEventTouchUpInside]
     subscribeNext:^(__kindof UIControl * _Nullable x) {
         @strongify(self)
         self.ignoreCurrentValue = NO;
     }];
    
    [[self.moveSlider rac_newValueChannelWithNilValue:@0]
     subscribeNext:^(NSNumber * x) {
         @strongify(self)
         float value = [x floatValue];
         self.currentTime = value * self.duration;
     }];
}



#pragma mark - properties

#pragma mark - private selectors

- (NSString *)formatSecondsToString:(NSInteger)seconds {
    NSString *hhmmss = nil;
    if (seconds < 0) {
        return @"00:00:00";
    }
    int h = (int)round((seconds % 86400) / 3600);
    int m = (int)round((seconds % 3600) / 60);
    int s = (int)round(seconds % 60);
    
    hhmmss = [NSString stringWithFormat:@"%02d:%02d:%02d", h, m, s];
    return hhmmss;
}

#pragma mark - getters

- (UIButton *)playbackButton {
    if (_playbackButton == nil) {
        _playbackButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_playbackButton setImage:[UIImage bcc_imageNamed:@"candy_play_btn"] forState:UIControlStateNormal];
        [_playbackButton setImage:[UIImage bcc_imageNamed:@"candy_play_btn"] forState:UIControlStateNormal | UIControlStateHighlighted];
        [_playbackButton setImage:[UIImage bcc_imageNamed:@"candy_pause_btn"] forState:UIControlStateSelected];
        [_playbackButton setImage:[UIImage bcc_imageNamed:@"candy_pause_btn"] forState:UIControlStateSelected | UIControlStateHighlighted];
        
        _playbackButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    }
    return _playbackButton;
}

- (UILabel *)currentLabel {
    if (_currentLabel == nil) {
        _currentLabel = [[UILabel alloc] init];
        _currentLabel.textColor = [UIColor whiteColor];
        _currentLabel.textAlignment = NSTextAlignmentCenter;
        _currentLabel.font = [UIFont systemFontOfSize:10];
        _currentLabel.text = @"00:00:00";
        [_currentLabel sizeToFit];
    }
    return _currentLabel;
}

- (UILabel *)durationLabel {
    if (_durationLabel == nil) {
        _durationLabel = [[UILabel alloc] init];
        _durationLabel.textColor = [UIColor whiteColor];
        _durationLabel.textAlignment = NSTextAlignmentCenter;
        _durationLabel.font = [UIFont systemFontOfSize:10];
        _durationLabel.text = @"00:00:00";
        [_durationLabel sizeToFit];
    }
    return _durationLabel;
}

- (UIButton *)screenButton {
    if (_screenButton == nil) {
        _screenButton = [UIButton buttonWithType:UIButtonTypeCustom];
        
        [_screenButton setImage:[UIImage bcc_imageNamed:@"candy_full_btn"] forState:UIControlStateNormal];
        [_screenButton setImage:[UIImage bcc_imageNamed:@"candy_full_btn"] forState:UIControlStateNormal | UIControlStateHighlighted];
        [_screenButton setImage:[UIImage bcc_imageNamed:@"candy_min_btn"] forState:UIControlStateSelected];
        [_screenButton setImage:[UIImage bcc_imageNamed:@"candy_min_btn"] forState:UIControlStateSelected | UIControlStateHighlighted];
        _screenButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    }
    return _screenButton;
}

- (UIButton *)rateButton {
    if (_rateButton == nil) {
        _rateButton = [UIButton buttonWithType:UIButtonTypeCustom];
        
        [_rateButton setTitle:@"1x" forState:UIControlStateNormal];
        _rateButton.titleLabel.textColor = [UIColor whiteColor];
        _rateButton.titleLabel.textAlignment = NSTextAlignmentCenter;
        _rateButton.titleLabel.font = [UIFont systemFontOfSize:12];
        _rateButton.layer.borderColor = [UIColor whiteColor].CGColor;
        _rateButton.layer.borderWidth = 0.5;
        _rateButton.layer.cornerRadius = 3;
    }
    return _rateButton;
}

- (UISlider *)moveSlider {
    if (_moveSlider == nil) {
        _moveSlider = [[UISlider alloc] init];
        _moveSlider.minimumValue = 0.0f;
        _moveSlider.maximumValue = 1.0f;
        _moveSlider.value = 0.0f;
        _moveSlider.continuous = NO;
        
        _moveSlider.maximumTrackTintColor = [UIColor colorWithWhite:0.8 alpha:1];
        _moveSlider.minimumTrackTintColor = [UIColor colorWithWhite:0.8 alpha:1];
        UIImage *thumbImage = [UIImage bcc_imageWithColor:[UIColor whiteColor] size:CGSizeMake(10, 10)];
        [_moveSlider setThumbImage:[thumbImage bcc_roundedCornerWithCornerRadius:5]
                          forState:UIControlStateNormal];
    }
    return _moveSlider;
}

- (UIProgressView *)progressView {
    if (_progressView == nil) {
        _progressView = [[UIProgressView alloc] init];
        _progressView.progressTintColor = [UIColor whiteColor];
        _progressView.progressViewStyle = UIProgressViewStyleDefault;
    }
    return _progressView;
}

@end
