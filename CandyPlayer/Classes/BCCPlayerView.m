//
//  BCCPlayerView.m
//  CandyPlayer
//
//  Created by 陈修武 on 2017/9/22.
//  Copyright © 2017年 baiwhte. All rights reserved.
//

/*! player views  */
#import "BCCPlayerView.h"
#import "BCCControlView.h"
#import "BCCPlaybackView.h"

#import "BCCMacro.h"

/*! apple framework  */
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>

/*! three lib  */
#import <ReactiveObjC/ReactiveObjC.h>

@interface BCCPlayerView()

/** 播放属性 */
@property (nonatomic, strong) AVPlayer               *player;
@property (nonatomic, strong) AVPlayerItem           *playerItem;
@property (nonatomic, strong) AVURLAsset             *urlAsset;

@property (nonatomic, strong) AVAssetImageGenerator  *imageGenerator;
/** set the playerLayer */
@property (nonatomic, strong) BCCPlaybackView        *playbackView;
@property (nonatomic, strong) id                     timeObserve;
/*! control view  */
@property (nonatomic, strong) BCCControlView         *controlView;
//MARK：为什么这里设置为strong会产生retain cycle????
@property (nonatomic, unsafe_unretained) UIView      *containterView;

/*! 重置订阅信号，若为YES表示不能接收next的值  */
@property (nonatomic, assign) BOOL                   resetAllSignal;

@property(nonatomic, readwrite) BCCPlayerStatus      status;

@property (nonatomic, assign) NSInteger              seekTime;
@property (nonatomic, assign) BOOL                   localVedio;
@property (nonatomic, assign,
           getter=isPauseByUser) BOOL                pauseByUser;

@end

@implementation BCCPlayerView

- (void)dealloc {
    [self resetPlayer];
    NSLog(@"BCCPlayerView dealloc");
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
    
    self.controlView.frame = self.bounds;
    self.playbackView.frame = self.bounds;
    
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    [super willMoveToSuperview:newSuperview];
    if (newSuperview && ![newSuperview isKindOfClass:UIWindow.class]) {
        self.containterView = newSuperview;
    }
}

- (void)initialize {
    [self addSubview:self.playbackView];
    [self addSubview:self.controlView];
    
    @weakify(self)
    [RACObserve(self, status) subscribeNext:^(NSNumber * x) {
        @strongify(self)
        BCCPlayerStatus status = (BCCPlayerStatus)[x integerValue];
        switch (status) {
            case BCCPlayerStatusPlaying:
                self.controlView.isPlayback = YES;
                self.controlView.isBuffering = NO;
                break;
            case BCCPlayerStatusBuffering:
                self.controlView.isBuffering = YES;
                break;
            case BCCPlayerStatusStopped:
                self.controlView.isPlayback = NO;
                self.controlView.isBuffering = NO;
                [self resetPlayer];
                break;
            default:
                break;
        }
    }];
    
    [[[RACObserve(self.controlView, isDragging) skip:1] distinctUntilChanged]
     subscribeNext:^(NSNumber * x) {
         @strongify(self)
         if (!x.boolValue) {
             [self setSeekTime:(NSInteger)self.controlView.currentTime];
         }
     }];
    
    [[RACObserve(self.controlView, isPlayback) skip:1] subscribeNext:^(NSNumber * x) {
        @strongify(self)
        if (!x.boolValue) {
            [self pause];
        } else {
            [self play];
        }
    }];
    
    [RACObserve(self.controlView, fullScreen) subscribeNext:^(NSNumber * x) {
        @strongify(self)
        [self togglePlayerViewFrame:x.boolValue];
    }];
    /* 播放状态
    RAC(self.controlView, isPlayback) = [RACObserve(self, status) map:^id _Nullable(NSNumber *value) {
        BCCPlayerStatus status = (BCCPlayerStatus)[value integerValue];
        return @(status == BCCPlayerStatusPlaying);
    }];
     */
    [self addApplicationNotification];
}

- (void)resetPlayer {
    [self.player pause];
    self.resetAllSignal = YES;
    [self removeTimeObserve];
    [self.player replaceCurrentItemWithPlayerItem:nil];
    self.imageGenerator = nil;
    self.player = nil;
    self.playerItem = nil;
}

- (void)playbackVideo {
    self.resetAllSignal  = NO;
    self.urlAsset = [AVURLAsset assetWithURL:self.controlView.item.vedioURL];
    self.playerItem = [AVPlayerItem playerItemWithAsset:self.urlAsset];

    @weakify(self)
    [[RACObserve(self.playerItem, status)
      takeUntilBlock:^BOOL(id  _Nullable x) {
          @strongify(self)
          return self.resetAllSignal;
      }]
     subscribeNext:^(NSNumber *status) {
         @strongify(self)
         AVPlayerItemStatus playerItemStatus = [status integerValue];
         if (playerItemStatus == AVPlayerItemStatusReadyToPlay) {
             [self addTimerObserve];
             if (self.seekTime) {
                 [self seekToTime:self.seekTime completionHandler:nil];
             } else {
                 self.status = BCCPlayerStatusPlaying;
             }
//             self.player.muted = self.mute;
         } else if (playerItemStatus == AVPlayerItemStatusFailed) {
             self.status = BCCPlayerStatusFailed;
         } else if (playerItemStatus == AVPlayerItemStatusUnknown) {
             [self removeTimeObserve];
         }
    }];
    
    [[RACObserve(self.playerItem, loadedTimeRanges)
      takeUntilBlock:^BOOL(id  _Nullable x) {
          @strongify(self)
          return self.resetAllSignal;
      }]
     subscribeNext:^(id  _Nullable x) {
        @strongify(self)
         // 计算缓冲进度
         CMTime playerDuration = [self playerItemDuration];
         if (CMTIME_IS_INVALID(playerDuration)) {
             return;
         }
         
         double duration = CMTimeGetSeconds(playerDuration);
         if (isfinite(duration)) {
             NSTimeInterval timeInterval = [self availableDuration];
             self.controlView.bufferValue = timeInterval / duration;
         }
    }];
    
    [[RACObserve(self.playerItem, playbackBufferEmpty)
      takeUntilBlock:^BOOL(id  _Nullable x) {
          @strongify(self)
          return self.resetAllSignal;
      }]
     subscribeNext:^(id  _Nullable x) {
         @strongify(self)
         // 当缓冲是空的时候
         if (self.playerItem.playbackBufferEmpty) {
             self.status = BCCPlayerStatusBuffering;
             [self bufferingSomeSeconds];
         }
    }];
    
    [[RACObserve(self.playerItem, playbackLikelyToKeepUp)
      takeUntilBlock:^BOOL(id  _Nullable x) {
          @strongify(self)
          return self.resetAllSignal;
      }]
     subscribeNext:^(NSNumber * x) {
         // 当缓冲好的时候
         @strongify(self)
         if (x.boolValue && self.status == BCCPlayerStatusBuffering){
             self.status = BCCPlayerStatusPlaying;
         }
    }];
    
    [[[[NSNotificationCenter defaultCenter] rac_addObserverForName:AVPlayerItemDidPlayToEndTimeNotification
                                                            object:self.playerItem]
      takeUntilBlock:^BOOL(id  _Nullable x) {
          @strongify(self)
          return self.resetAllSignal;
      }]
     subscribeNext:^(NSNotification * notification) {
         @strongify(self)
         self.status = BCCPlayerStatusStopped;
     }];
    
    self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"10.0")) {
        self.player.automaticallyWaitsToMinimizeStalling = NO;
    }
    /* Observe the AVPlayer "currentItem" property to find out when any
     AVPlayer replaceCurrentItemWithPlayerItem: replacement will/did
     occur.*/
    [[RACObserve(self.player, currentItem) takeUntilBlock:^BOOL(id  _Nullable x) {
        @strongify(self)
        return self.resetAllSignal;
    }] subscribeNext:^(AVPlayerItem *playerItem) {
        @strongify(self)
        NSLog(@"currentItem:%@", playerItem);
        if (playerItem == nil) {
            return ;
        }
        [self.playbackView setPlayer:self.player];
        [self.playbackView setVideoFillMode:AVLayerVideoGravityResizeAspect];
    }];

    [[RACObserve(self.player, rate) takeUntilBlock:^BOOL(id  _Nullable x) {
        @strongify(self)
        return self.resetAllSignal;
    }] subscribeNext:^(NSNumber *rate) {
        NSLog(@"rate:%@", rate);
    }];
    
}

- (void)addApplicationNotification {
    [[[[NSNotificationCenter defaultCenter] rac_addObserverForName:UIApplicationWillResignActiveNotification object:nil]
     takeUntil:self.rac_willDeallocSignal]
     subscribeNext:^(NSNotification * notification) {
         
     }];
    
    [[[[NSNotificationCenter defaultCenter] rac_addObserverForName:UIApplicationDidBecomeActiveNotification object:nil]
     takeUntil:self.rac_willDeallocSignal]
     subscribeNext:^(NSNotification * notification) {
         
     }];
}

#pragma mark - public methods

- (void)playbackWithPlyerItem:(BCCPlayerItem *)playerItem inContainerView:(UIView *)containerView {
    NSParameterAssert(playerItem != nil && playerItem.vedioURL != nil);
    
    if (self.player) {
        [self resetPlayer];
    }
    if (containerView) {
        self.containterView = containerView;
    }
    self.controlView.item = playerItem;
    [self playbackVideo];
}

/**
 *  播放
 */
- (void)play {
    if (self.status == BCCPlayerStatusPause) { self.status = BCCPlayerStatusPlaying; }
    self.pauseByUser = NO;
    [self.player play];
}

/**
 * 暂停
 */
- (void)pause {
    if (self.status == BCCPlayerStatusPlaying) { self.status = BCCPlayerStatusPause;}
    self.pauseByUser = YES;
    [self.player pause];
}

#pragma mark - player methods

- (void)seekToTime:(NSInteger)dragedSeconds completionHandler:(void (^)(BOOL finished))completionHandler {
    if (self.player.currentItem.status == AVPlayerItemStatusReadyToPlay) {
        [self.player pause];
        CMTime dragedCMTime = CMTimeMake(dragedSeconds, 1); //kCMTimeZero
        @weakify(self)
        [self.player seekToTime:dragedCMTime toleranceBefore:CMTimeMake(1,1) toleranceAfter:CMTimeMake(1,1) completionHandler:^(BOOL finished) {
            @strongify(self)
            // 视频跳转回调
            if (completionHandler) { completionHandler(finished); }
            if (!self.pauseByUser) {
                [self.player play];
            }
            
            self.seekTime = 0;
            if (!self.playerItem.isPlaybackLikelyToKeepUp && !self.localVedio) {
                self.status = BCCPlayerStatusBuffering;
            }
            
        }];
    }
}

/**
 *  计算缓冲进度
 *
 *  @return 缓冲进度
 */
- (NSTimeInterval)availableDuration {
    NSArray *loadedTimeRanges = [[_player currentItem] loadedTimeRanges];
    CMTimeRange timeRange     = [loadedTimeRanges.firstObject CMTimeRangeValue];// 获取缓冲区域
    float startSeconds        = CMTimeGetSeconds(timeRange.start);
    float durationSeconds     = CMTimeGetSeconds(timeRange.duration);
    NSTimeInterval result     = startSeconds + durationSeconds;// 计算缓冲总进度
    return result;
}

- (void)bufferingSomeSeconds {
    self.status = BCCPlayerStatusBuffering;
    __block BOOL isBuffering = NO;
    if (isBuffering) return;
    isBuffering = YES;
    [self.player pause];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{

        isBuffering = NO;
        // 如果此时用户已经暂停了，则不再需要开启播放了
        if (self.isPauseByUser) {
            return;
        }

        [self play];
        if (!self.playerItem.isPlaybackLikelyToKeepUp) { [self bufferingSomeSeconds]; }

    });
}

- (void)addTimerObserve {

    @weakify(self);
    self.timeObserve = [self.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(1, NSEC_PER_SEC)
                                                                 queue:nil
                                                            usingBlock:^(CMTime time){
        @strongify(self)
        /** 拖动滑动条时不设置播放进度 */
        if (self.controlView.isDragging) { return ; }
                                                                
        AVPlayerItem *currentItem = self.playerItem;
        NSArray *loadedRanges = currentItem.seekableTimeRanges;
        if (loadedRanges.count > 0 && currentItem.duration.timescale != 0) {
            Float64 currentTime = CMTimeGetSeconds([currentItem currentTime]);
            CGFloat totalTime     = (CGFloat)currentItem.duration.value / currentItem.duration.timescale;
            self.controlView.duration    = totalTime;
            self.controlView.currentTime = currentTime;
        }
    }];
}

- (void)removeTimeObserve {
    if (self.timeObserve) {
        [self.player removeTimeObserver:self.timeObserve];
        self.timeObserve = nil;
    }
}

- (CMTime)playerItemDuration {
    AVPlayerItem *playerItem = [self.player currentItem];
    if (playerItem.status == AVPlayerItemStatusReadyToPlay) {
        return([playerItem duration]);
    }
    
    return(kCMTimeInvalid);
}

- (void)switchPlayerViewFrame:(BOOL)toFullScreen {
    self.controlView.fullScreen = toFullScreen;
}

- (void)togglePlayerViewFrame:(BOOL)fullScreen {
    NSTimeInterval animateDuration = [UIApplication sharedApplication].statusBarOrientationAnimationDuration;
    UIInterfaceOrientation currentOrientation = [UIApplication sharedApplication].statusBarOrientation;
    [self removeFromSuperview];
    if (fullScreen) {
        
        [UIView animateWithDuration:animateDuration animations:^{
            
            [[UIApplication sharedApplication].keyWindow addSubview:self];
            CGRect bound   = [UIScreen mainScreen].bounds;
            self.frame     = CGRectMake(0, 0, bound.size.height, bound.size.width);
            self.transform = CGAffineTransformMakeRotation(M_PI_2);
            self.center    = [UIApplication sharedApplication].keyWindow.center;
            if (currentOrientation != UIInterfaceOrientationLandscapeRight) {
                [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationLandscapeRight animated:NO];
            }
            
        } completion:^(BOOL finished) {
            if (finished) {
            }
            
        }];
    } else {

        [self.containterView addSubview:self];
        [UIView animateWithDuration:animateDuration animations:^{
            
            self.transform = CGAffineTransformIdentity;
            self.frame = self.containterView.bounds;
//            self.center = self.containterView.center;
            if (currentOrientation != UIInterfaceOrientationPortrait) {
                [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationPortrait animated:YES];
            }
            
        } completion:^(BOOL finished) {
            
        }];
    }
    
    
}

- (CGAffineTransform)transformRotationAngle {
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    if (orientation == UIInterfaceOrientationPortrait) {
        return CGAffineTransformIdentity;
    } else if (orientation == UIInterfaceOrientationLandscapeLeft) {
        return CGAffineTransformMakeRotation(-M_PI_2);
    } else if(orientation == UIInterfaceOrientationLandscapeRight) {
        return CGAffineTransformMakeRotation(M_PI_2);
    }
    return CGAffineTransformIdentity;
}

#pragma mark - setters


#pragma mark - properties

- (BCCControlView *)controlView {
    if (_controlView == nil) {
        _controlView = [[BCCControlView alloc] init];
    }
    return _controlView;
}

- (BCCPlaybackView *)playbackView {
    if (_playbackView == nil) {
        _playbackView = [[BCCPlaybackView alloc] init];
    }
    return _playbackView;
}

@end
