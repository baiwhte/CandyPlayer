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

#import <MediaPlayer/MediaPlayer.h>
#import <ReactiveObjC/ReactiveObjC.h>

typedef NS_ENUM(NSInteger, BCCDirection) {
    BCCLeftOrRight,
    BCCUpOrDown,
    BCCNone
};

@interface BCCControlView()<UIGestureRecognizerDelegate>

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

//单击手势
@property (nonatomic, strong) UITapGestureRecognizer *tapGesture;
//双击手势
@property (nonatomic, strong) UITapGestureRecognizer *doubleTapGesture;
//滑动手势
@property (nonatomic, strong) UIPanGestureRecognizer *panGesture;

@property (nonatomic, strong) UISwipeGestureRecognizer *swipeLeftGesture;

@property (nonatomic, strong) MPVolumeView *volumeView;
@property (nonatomic, strong) UISlider * volumeViewSlider;

//滑动的起始点
@property (nonatomic, assign) CGPoint startPoint;
@property (nonatomic, assign) BCCDirection direction;

@property (nonatomic, assign) CGFloat oldLumina;
@property (nonatomic, assign) CGFloat oldVolume;
@property (nonatomic, assign) CGFloat luminance;//亮度(0-1)

@property (nonatomic, assign) CGFloat oldTime;
@property (nonatomic, assign) CGFloat seekTime;

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

- (void)addGestures {
    @weakify(self)
    [[self.tapGesture rac_gestureSignal] subscribeNext:^(UITapGestureRecognizer * x) {
        @strongify(self)
        if (!self.showing) {
            [self showControlView];
        }
        else {
            [self hideControlView];
        }
    }];
    self.tapGesture.delegate = self;
    [self addGestureRecognizer:self.tapGesture];
    [[self.doubleTapGesture rac_gestureSignal] subscribeNext:^(UITapGestureRecognizer * x) {
        @strongify(self)
        self.isPlayback = !self.isPlayback;
    }];
    [self addGestureRecognizer:self.doubleTapGesture];
    [[self.panGesture rac_gestureSignal] subscribeNext:^(UIPanGestureRecognizer * x) {
        @strongify(self)
        switch (x.state) {
            case UIGestureRecognizerStateBegan:
                self.startPoint = [x translationInView:self];
                self.oldLumina = self.luminance;
                self.oldVolume = self.volumeViewSlider.value;
                
                self.oldTime = self.currentTime;
                self.seekTime = 0;
                break;
            case UIGestureRecognizerStateChanged: {
                CGPoint currentPoint = [x translationInView:self];
                if (self.direction == BCCNone) {
                    if (ABS(currentPoint.x - self.startPoint.x) >
                        ABS(currentPoint.y - self.startPoint.y)) {
                        self.direction = BCCLeftOrRight;
                    }  else {
                        //根据触发位置来决定（左边亮度，右边音量）
                        self.direction = BCCUpOrDown;
                    }
                }
                
                if (self.direction == BCCNone) {
                    return ;
                }
                CGFloat screenScale = [UIScreen mainScreen].scale;
                if (self.direction == BCCUpOrDown) {
                    
                    CGFloat uint = (currentPoint.y - self.startPoint.y) / (5 * screenScale);
                    if (ABS(uint) < 1) {
                        return ;
                    }
                    if ([x locationInView:self].x < CGRectGetMidX(self.bounds)) {
                        [self changeLumina:-uint];
                    } else {
                        [self changeVolume:-uint];
                    }
                    
                } else if (self.direction == BCCLeftOrRight) {
                    CGFloat uint = (currentPoint.x - self.startPoint.x) / (5 * screenScale);
                    if (ABS(uint) < 1 || self.isBuffering) {
                        return ;
                    }
                    NSInteger time = self.oldTime + uint;
                    if (time < 0) {
                        time = 0;
                    } else if (time > self.duration) {
                        time = self.duration;
                    }
                    
                    if (time == 0) {
                        
                    }
                    self.seekTime = time / self.duration;
                }
                break;
            }
            case UIGestureRecognizerStateEnded:
                if (self.direction == BCCLeftOrRight) {
                    [self.sliderSubject sendNext: RACTuplePack(@1, @(self.seekTime))];
                }
                self.direction = BCCNone;
                [[NSNotificationCenter defaultCenter] postNotificationName:@"PlayerOperation" object:nil];
                break;
            case UIGestureRecognizerStateCancelled:
                self.direction = BCCNone;
                [[NSNotificationCenter defaultCenter] postNotificationName:@"PlayerOperation" object:nil];
                break;
            default:
                self.direction = BCCNone;
                break;
        }
    }];
    [self addGestureRecognizer:self.panGesture];
}

- (void)setLuminance:(CGFloat)luminance {
    
    if (luminance < 0.1) {
        luminance = 0.1;
    } else if (luminance > 1) {
        luminance = 1;
    }
    [[UIScreen mainScreen] setBrightness:luminance];
    
}

- (CGFloat)luminance {
    return [UIScreen mainScreen].brightness;
}

- (void)changeLumina:(NSInteger)change {
    self.luminance = _oldLumina + change * 0.05;
}

- (float)volume {
    return self.volumeViewSlider.value;
}

- (void)setVolume:(float)value {
    self.volumeViewSlider.value = value;
}

- (void)changeVolume:(NSInteger)change {
    float newVolume = _oldVolume + change * 0.05;
    if (newVolume > 1) {
        newVolume = 1;
    } else if (newVolume < 0) {
        newVolume = 0;
    }
    self.volumeViewSlider.value = newVolume;
}

#pragma mark - UIGestureRecognizerDelegate


- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    NSString *className = NSStringFromClass([touch.view class]);
    
    if ([className isEqualToString:@"UITableViewCellContentView"]) {
        return NO;
    }
    if (![className isEqualToString:@"BCCControlView"]) {
        return NO;
    }
    
    if (self.panGesture == gestureRecognizer) {
        CGPoint startPoint = [touch locationInView:self];
        CGRect rect = self.bounds;
        CGRect rightRect = CGRectMake(rect.size.width * 0.9, 0, rect.size.width * 0.1, rect.size.height);
        if (CGRectContainsPoint(rightRect, startPoint)) {
            return NO;
        }
    }
    return YES;
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

- (UITapGestureRecognizer *)tapGesture {
    if (_tapGesture == nil) {
        _tapGesture = [[UITapGestureRecognizer alloc] init];
        _tapGesture.numberOfTapsRequired = 1;
        _tapGesture.numberOfTouchesRequired = 1;
    }
    return _tapGesture;
}

- (UITapGestureRecognizer *)doubleTapGesture {
    if (_doubleTapGesture == nil) {
        _doubleTapGesture = [[UITapGestureRecognizer alloc] init];
        _doubleTapGesture.numberOfTapsRequired = 2;
    }
    return _doubleTapGesture;
}

- (UIPanGestureRecognizer *)panGesture {
    if (_panGesture == nil) {
        _panGesture = [[UIPanGestureRecognizer alloc] init];
        _panGesture.minimumNumberOfTouches = 1;
        _panGesture.maximumNumberOfTouches = 1;
        //        _panGesture.delegate = self;
    }
    return _panGesture;
}

- (UISwipeGestureRecognizer *)swipeLeftGesture {
    if (_swipeLeftGesture == nil) {
        _swipeLeftGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handlerSwipe:)];
        //
        _swipeLeftGesture.direction = UISwipeGestureRecognizerDirectionLeft;
        [self addGestureRecognizer:_swipeLeftGesture];
        [_swipeLeftGesture requireGestureRecognizerToFail:_panGesture];
    }
    return _swipeLeftGesture;
}


- (void)setIsReadyToPlay:(BOOL)isReadyToPlay {
    _isReadyToPlay = isReadyToPlay;
    if (!isReadyToPlay) {
        [self addGestures];
    }
}

@end
