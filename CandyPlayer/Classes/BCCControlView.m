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
#import "BCCPlayerView.h"

#import <ReactiveObjC/ReactiveObjC.h>

@interface BCCControlView()

@property (nonatomic, strong) BCCTopView              *topView;
@property (nonatomic, strong) BCCBottomView           *bottomView;

@property (nonatomic, strong) UIButton                *lockButton;

@property (nonatomic, strong) UIActivityIndicatorView *indicatorView;
/*! 是否向前拖动滑块  */
@property (nonatomic, assign) BOOL                     dragForward;
/*! 拖动时滑块的最新位置  */
@property (nonatomic, assign) CGFloat                  lastDragValue;

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
}

- (void)initialize {
    self.backgroundColor = [UIColor clearColor];
//    [self addSubview:self.topView];
    [self addSubview:self.indicatorView];
    [self addSubview:self.bottomView];
    @weakify(self)
    [self.bottomView.playCommand.executionSignals subscribeCompleted:^{
        
    }];
    
    [self.bottomView.fullScreenCommand.executionSignals subscribeCompleted:^{
        
    }];
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
            self.bottomView.currentTime = [self stringByPlaySeconds:dragedSeconds];
            if (self.playerView.allowPreview) {
                [self.sliderSubject sendNext:number];
            }
        }
    }];
    
    
    [[RACObserve(self.playerView, status) skip:1]
     subscribeNext:^(NSNumber *number) {
         @strongify(self)
         self.bottomView.playOrPause = (number.integerValue == BCCPlayerStatusPlaying);
         if (number.integerValue == BCCPlayerStatusPlaying) {
             [self.indicatorView stopAnimating];
         } else if (number.integerValue == BCCPlayerStatusBuffering) {
             [self.indicatorView startAnimating];
         }
     }];
    RACSignal *fullScreenSignal = RACObserve(self.playerView, horizontalScreen);
    RAC(self.bottomView, fullScreen) = fullScreenSignal.deliverOnMainThread;
    [[fullScreenSignal skip:1] subscribeNext:^(NSNumber *number) {
        @strongify(self)
        if (number.boolValue) {
            [self addSubview:self.topView];
        } else {
            [self.topView removeFromSuperview];
        }
    }];
    
    [[[RACSignal combineLatest:@[RACObserve(self, currentTime),
                                 RACObserve(self, duration)]]
     deliverOnMainThread]
     subscribeNext:^(RACTuple * tuple) {
         @strongify(self)
         Float64 cur = [tuple.first doubleValue];
         NSInteger total = [tuple.second integerValue];
         if (total == 0) {
             return ;
         }
         self.bottomView.currentTime = [self stringByPlaySeconds:cur];
         self.bottomView.totalTime   = [self stringByPlaySeconds:total];
         self.bottomView.sliderValue = (CGFloat)cur / total;
     }];
     
     [RACObserve(self, bufferValue) subscribeNext:^(NSNumber *number) {
         self.bottomView.progressViewValue = number.floatValue;
     }];
    
    [[RACSignal combineLatest:@[RACObserve(self, currentTime), RACObserve(self, duration)]]
     subscribeNext:^(RACTuple * tuple) {
         Float64 cur = [tuple.first doubleValue];
         NSInteger total = [tuple.second integerValue];
         if (cur == 0 || total == 0) {
             return ;
         }
     }];
    
    [self.topView.backCommand.executionSignals subscribeCompleted:^{
        
    }];
    
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

- (NSString *)stringByPlaySeconds:(Float64)playSeconds {
    NSInteger nPlaySeconds = (NSInteger)playSeconds;
    NSInteger hour = nPlaySeconds / 3600;
    NSInteger minute = (nPlaySeconds - hour * 3600) / 60;
    NSInteger seconds = nPlaySeconds - hour * 3600 - minute * 60;
    return [NSString stringWithFormat:@"%.02zd:%.02zd:%.02zd", ABS(hour), ABS(minute), ABS(seconds)];
}

#pragma mark - properties

- (BCCTopView *)topView {
    if (_topView == nil) {
        _topView = [[BCCTopView alloc] init];
    }
    return _topView;
}

- (BCCBottomView *)bottomView {
    if (_bottomView) {
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
