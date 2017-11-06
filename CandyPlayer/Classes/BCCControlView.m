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

#import "BCCPlayerItem.h"

#import <ReactiveObjC/ReactiveObjC.h>

@interface BCCControlView()

@property (nonatomic, strong) BCCTopView              *topView;
@property (nonatomic, strong) BCCBottomView           *bottomView;
@property (nonatomic, assign) BOOL                    showing;

//@property (nonatomic, strong) BCCVideoTypeView *videoTypeView;
//@property (nonatomic, strong) BCCSettingView *settingView;

@property (nonatomic, strong) UIButton                *lockButton;

@property (nonatomic, strong) UIActivityIndicatorView *indicatorView;
/*! 是否向前拖动滑块  */
@property (nonatomic, assign) BOOL                     dragForward;
/*! 拖动时滑块的最新位置  */
@property (nonatomic, assign) CGFloat                  lastDragValue;

@property (nonatomic, assign) BOOL isDragging;

@property (nonatomic, assign) BOOL hasAddTopView;

@end

@implementation BCCControlView

- (void)dealloc {
    NSLog(@"BCCControlView dealloc");
}

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
        CGFloat statusBarHeight = CGRectGetHeight([UIApplication sharedApplication].statusBarFrame);
        statusBarHeight = statusBarHeight > 0 ?: 20;
        self.topView.frame = CGRectMake(0, 0, size.width, height + statusBarHeight);
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
    

    _sliderSubject = [RACReplaySubject subject];

    @weakify(self)
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

    RACChannelTo(self.bottomView, isDragging)  = RACChannelTo(self, isDragging);
    [[RACObserve(self, fullScreen) distinctUntilChanged]
     subscribeNext:^(NSNumber * x) {
         @strongify(self)
         if (!x.boolValue) {
             [self removeTopView];
         } else {
             [self addTopView];
         }
         [self showControlView];
     }];
}

#pragma mark - private methods

- (void)showControlView {
    if (self.showing) { return; }
    self.showing = YES;
    [self cancelAutoHide];
    self.topView.alpha = 0;
    self.bottomView.alpha = 0;
    [UIView animateWithDuration:0.25 animations:^{
        self.topView.alpha = 1;
        self.bottomView.alpha = 1;
    } completion:^(BOOL finished) {
        [self autoHideControlView];
    }];
}

- (void)hideControlView {
    if (!self.showing) { return; }
    self.showing = NO;
    [self cancelAutoHide];
    self.topView.alpha = 1;
    self.bottomView.alpha = 1;
    [UIView animateWithDuration:0.25 animations:^{
        self.topView.alpha = 0;
        self.bottomView.alpha = 0;
    } completion:^(BOOL finished) {
        
    }];
}

- (void)autoHideControlView {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideControlView) object:nil];
    [self performSelector:@selector(hideControlView) withObject:nil afterDelay:7];
}

- (void)cancelAutoHide {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideControlView) object:nil];
}

- (void)addTopView {
    [self.topView removeFromSuperview];
    self.hasAddTopView = YES;
    [self addSubview:self.topView];
    
    self.topView.title = self.fullScreen ? self.item.title : @"";
    self.bottomView.hideScreenButton = ![[self.item.vedioURL scheme] hasPrefix:@"http"];
    @weakify(self)
    [[self.topView.subject takeUntilBlock:^BOOL(id  _Nullable x) {
        @strongify(self)
        return !self.hasAddTopView;
    }] subscribeNext:^(NSNumber * x) {
        @strongify(self)
        switch (x.integerValue) {
            case BCCTopBackButton:
                self.fullScreen = NO;
                break;
            case BCCTopQualityButton:
                break;
            case BCCTopSettingButton:
                break;
            default:
                break;
        }
    }];
    

}

- (void)removeTopView {
    self.hasAddTopView = NO;
    [self.topView removeFromSuperview];
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
