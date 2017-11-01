//
//  BCCBottomView.m
//  CandyPlayer
//
//  Created by 陈修武 on 2017/9/25.
//  Copyright © 2017年 baiwhte. All rights reserved.
//

#import "BCCBottomView.h"

#import <ReactiveObjC/ReactiveObjC.h>

@interface BCCBottomView()

/*! 播放与暂停按钮  */
@property (nonatomic, strong) UIButton       *playButton;

@property (nonatomic, strong) UILabel        *currentTimeLabel;

@property (nonatomic, strong) UISlider       *moveTimeSlider;
@property (nonatomic, strong) UIProgressView *progressView;

@property (nonatomic, strong) UILabel        *durationLabel;

@property (nonatomic, strong) UIButton       *rateButton;

@property (nonatomic, strong) UIButton       *fullScreenButton;

@property (nonatomic, strong) RACSequence    *rateSignal;
@property (nonatomic, strong) RACSequence    *tailSignal;

@end

@implementation BCCBottomView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        
    }
    return self;
}

- (void)initialize {
    self.rateSignal = [@[@(.5), @(1.0), @(1.25), @(1.5), @(1.75), @(2.0)] rac_sequence];
    self.tailSignal = self.rateSignal.tail;
    [self addSubview:self.playButton];
    [self addSubview:self.currentTimeLabel];
    [self addSubview:self.moveTimeSlider];
    [self addSubview:self.progressView];
    [self addSubview:self.durationLabel];
    [self addSubview:self.rateButton];
    [self addSubview:self.fullScreenButton];
    [self initCommand];
    [self changeRate];
//    self.playButton.selected       = RACObserve(self, playOrPause).deliverOnMainThread;
//    self.fullScreenButton.selected = RACObserve(self, fullScreen).deliverOnMainThread;
}

- (void)initCommand {
    RACCommand *command = [[RACCommand alloc] initWithSignalBlock:^RACSignal * (id input) {
        return [RACSignal return:input];
    }];
    _playCommand = command;
    self.playButton.rac_command = command;
    @weakify(self)
    self.rateButton.rac_command = [[RACCommand alloc] initWithSignalBlock:^RACSignal * (id input) {
        @strongify(self)
        [self changeRate];
        return [RACSignal empty];
    }];
    _fullScreenCommand = command;
    _fullScreenButton.rac_command = command;
    
    _subject = [RACReplaySubject subject];
    
    [[self.moveTimeSlider rac_signalForControlEvents:UIControlEventTouchDown]
     subscribeNext:^(UISlider * slider) {
         @strongify(self)
         [self.subject sendNext:@YES];
     }];
    
    [[self.moveTimeSlider rac_signalForControlEvents:UIControlEventValueChanged]
     subscribeNext:^(UISlider * slider) {
         @strongify(self)
         [self.subject sendNext:@(slider.value)];
    }];
    
    [[[self.moveTimeSlider rac_signalForControlEvents:UIControlEventTouchUpOutside |
                                                      UIControlEventTouchUpInside]
     takeUntil:self.rac_willDeallocSignal]
     subscribeNext:^(UISlider * slider) {
         @strongify(self)
         [self.subject sendNext:@NO];
    }];
}

- (void)changeRate {
    NSNumber *rate = self.tailSignal.head;
    if (rate == nil) {
        rate = self.rateSignal.head;
    }
    [self.rateButton setTitle:[NSString stringWithFormat:@"%@x", rate]
                     forState:UIControlStateNormal];
}

- (void)setCurrentTime:(NSString *)currentTime {
    _currentTime = currentTime;
    _currentTimeLabel.text = currentTime;
}

- (void)setTotalTime:(NSString *)totalTime {
    _totalTime = totalTime;
    _durationLabel.text = totalTime;
}

- (void)setSliderValue:(CGFloat)sliderValue {
    _sliderValue = sliderValue;
    _moveTimeSlider.value = sliderValue;
}

- (void)setProgressViewValue:(CGFloat)value {
    _progressViewValue = value;
    [_progressView setProgress:value animated:NO];
}

#pragma mark - properties

- (UIButton *)playButton {
    if (_playButton == nil) {
        _playButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_playButton setImage:[UIImage imageNamed:@"coursePlayerPlayBtn"] forState:UIControlStateNormal];
        [_playButton setImage:[UIImage imageNamed:@"coursePlayerPlayBtn"] forState:UIControlStateNormal | UIControlStateHighlighted];
        [_playButton setImage:[UIImage imageNamed:@"coursePlayerSuspendBtn"] forState:UIControlStateSelected];
        [_playButton setImage:[UIImage imageNamed:@"coursePlayerSuspendBtn"] forState:UIControlStateSelected | UIControlStateHighlighted];
        _playButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    }
    return _playButton;
}

- (UILabel *)currentTimeLabel {
    if (_currentTimeLabel == nil) {
        _currentTimeLabel = [[UILabel alloc] init];
        _currentTimeLabel.textColor = [UIColor whiteColor];
        _currentTimeLabel.textAlignment = NSTextAlignmentCenter;
        _currentTimeLabel.font = [UIFont systemFontOfSize:10];
        _currentTimeLabel.text = @"00:00:00";
        [_currentTimeLabel sizeToFit];
    }
    return _currentTimeLabel;
}

- (UISlider *)moveTimeSlider {
    if (_moveTimeSlider == nil) {
        _moveTimeSlider = [[UISlider alloc] initWithFrame:CGRectZero];
        _moveTimeSlider.continuous = YES;
        _moveTimeSlider.maximumTrackTintColor = [UIColor colorWithWhite:0.8 alpha:1];
        _moveTimeSlider.minimumTrackTintColor = [UIColor colorWithWhite:0.8 alpha:1];
    }
    return _moveTimeSlider;
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

- (UIButton *)fullScreenButton{
    if (_fullScreenButton == nil) {
        _fullScreenButton = [UIButton buttonWithType:UIButtonTypeCustom];

        [_fullScreenButton setImage:[UIImage imageNamed:@"coursePlayerFullBtn"] forState:UIControlStateNormal];
        [_fullScreenButton setImage:[UIImage imageNamed:@"coursePlayerFullBtn"] forState:UIControlStateNormal | UIControlStateHighlighted];
        [_fullScreenButton setImage:[UIImage imageNamed:@"coursePlayerMinBtn"] forState:UIControlStateSelected];
        [_fullScreenButton setImage:[UIImage imageNamed:@"coursePlayerMinBtn"] forState:UIControlStateSelected | UIControlStateHighlighted];
        _fullScreenButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    }
    return _fullScreenButton;
}

@end
