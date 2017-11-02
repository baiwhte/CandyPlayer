//
//  BCCControlView.m
//  CandyPlayer
//
//  Created by 陈修武 on 2017/9/22.
//  Copyright © 2017年 baiwhte. All rights reserved.
//

#import "BCCControlView.h"

#import "BCCTopView.h"
#import "BCCBottomView.h"

#import <ReactiveObjC/ReactiveObjC.h>

@interface BCCControlView()

@property (nonatomic, strong) BCCTopView              *topView;
@property (nonatomic, strong) BCCBottomView           *bottomView;

//@property (nonatomic, strong) BCCVideoTypeView *videoTypeView;
//@property (nonatomic, strong) BCCSettingView *settingView;

@property (nonatomic, strong) UIButton                *lockButton;

@property (nonatomic, strong) UIActivityIndicatorView *indicatorView;
/*! 是否向前拖动滑块  */
@property (nonatomic, assign) BOOL                     dragForward;
/*! 拖动时滑块的最新位置  */
@property (nonatomic, assign) CGFloat                  lastDragValue;

@property (nonatomic, assign) BOOL hasAddTopView;

@end

@implementation BCCControlView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self initialize];
    }
    return self;
}


- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self initialize];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGSize size = self.bounds.size;
    if (CGSizeEqualToSize(size, CGSizeZero)) { return; }
    
    CGFloat height = 44;
    
    self.bottomView.frame = CGRectMake(0, size.height - height, size.width, height);
    if (self.hasAddTopView) {
        self.topView.frame = CGRectMake(0, 0, size.width, height + 20);
    }
    self.indicatorView.center = self.center;
    
//    _settingView.frame = self.bounds;
//    _videoTypeView.frame = self.bounds;
}

- (void)initialize {
    self.backgroundColor = [UIColor clearColor];
//    [self addSubview:self.topView];
    [self addSubview:self.indicatorView];
    [self addSubview:self.bottomView];
    @weakify(self)

    _sliderSubject = [RACReplaySubject subject];
    [self.bottomView.subject subscribeNext:^(NSNumber *number) {
        @strongify(self)
        if ([number isKindOfClass:NSClassFromString(@"__NSCFBoolean")]) {
            [self.sliderSubject sendNext:number];
        } else {
            BOOL style = false;
            CGFloat value   = number.floatValue - self.lastDragValue;
            if (value > 0) { style = YES; }
            if (value < 0) { style = NO; }
            if (value == 0) { return; }
            self.lastDragValue = number.floatValue;
            //计算出拖动的当前秒数
            CGFloat dragedSeconds = floorf(self.duration * number.floatValue);
    
        }
    }];
    
    RACSignal *bufferSignal = RACObserve(self, isBuffering);
    [bufferSignal subscribeNext:^(NSNumber * x) {
        @strongify(self)
        if (!x.boolValue) {
            [self.indicatorView stopAnimating];
        } else {
            [self.indicatorView startAnimating];
        }
        self.isPlayback = !x.boolValue;
    }];
    
    RACChannelTo(self.bottomView, isPlayback)  = RACChannelTo(self, isPlayback);
    RACChannelTo(self.bottomView, fullScreen)  = RACChannelTo(self, fullScreen);
    RACChannelTo(self.bottomView, currentTime) = RACChannelTo(self, currentTime);
    RACChannelTo(self.bottomView, duration)    = RACChannelTo(self, duration);


}

#pragma mark - private methods

- (void)showControlView {
    
}

- (void)hideControlView {
    
}

- (void)autoHideControlView {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(showControlView) object:nil];
    [[RACScheduler scheduler] afterDelay:5 schedule:^{
        
    }];
}

#pragma mark - properties

- (BCCTopView *)topView {
    if (_topView == nil) {
        _topView = [[BCCTopView alloc] init];
    }
    return _topView;
}

- (BCCBottomView *)bottomView {
    if (_bottomView == nil) {
        _bottomView = [[BCCBottomView alloc] init];
    }
    return _bottomView;
}

- (UIActivityIndicatorView *)indicatorView {
    if (_indicatorView == nil) {
        _indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        _indicatorView.hidesWhenStopped = YES;
    }
    return _indicatorView;
}

@end
