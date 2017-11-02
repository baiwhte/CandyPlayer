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
@property (nonatomic, strong) UIView                 *containterView;

@property (nonatomic, strong) BCCPlayerItem          *playbackItem;
/*! 重置订阅信号，若为YES表示不能接收next的值  */
@property (nonatomic, assign) BOOL                   resetAllSignal;

@property(nonatomic, readwrite) BCCPlayerStatus      status;

@property (nonatomic, assign) NSInteger              seekTime;
@property (nonatomic, assign) BOOL                   localVedio;
@property (nonatomic, assign) BOOL                   dragging;

@property (nonatomic, assign) BOOL                   ignoreValues;

@end

@implementation BCCPlayerView

- (void)dealloc {
    [self resetPlayer];
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
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
    
    [RACObserve(self.controlView, isPlayback) subscribeNext:^(NSNumber * x) {
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
}

- (void)resetPlayer {
    [self.player pause];
    self.resetAllSignal = YES;
    [self removeTimeObserve];
    [self.player replaceCurrentItemWithPlayerItem:nil];
    self.imageGenerator = nil;
    self.player = nil;
    self.playerItem = nil;
    self.playbackItem = nil;
}

- (void)playbackVideo {
    self.resetAllSignal  = NO;
    self.urlAsset = [AVURLAsset assetWithURL:self.playbackItem.vedioURL];
    self.playerItem = [AVPlayerItem playerItemWithAsset:self.urlAsset];
    
    @weakify(self)
    [[RACObserve(self.playerItem, status)
      takeUntilBlock:^BOOL(id  _Nullable x) {
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
          return self.resetAllSignal;
      }]
     subscribeNext:^(NSNotification * notification) {
         @strongify(self)
         self.status = BCCPlayerStatusStopped;
     }];
    
    self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
    
    /* Observe the AVPlayer "currentItem" property to find out when any
     AVPlayer replaceCurrentItemWithPlayerItem: replacement will/did
     occur.*/
    [[RACObserve(self.player, currentItem) takeUntilBlock:^BOOL(id  _Nullable x) {
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
    
    // 监测设备方向
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[[[NSNotificationCenter defaultCenter] rac_addObserverForName:UIDeviceOrientationDidChangeNotification object:nil]
     takeUntil:self.rac_willDeallocSignal]
     subscribeNext:^(NSNotification * notification) {
         
     }];
    
    [[[[NSNotificationCenter defaultCenter] rac_addObserverForName:UIApplicationDidChangeStatusBarOrientationNotification object:nil]
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
    _playbackItem = playerItem;
    [self playbackVideo];
}

/**
 *  播放
 */
- (void)play {
//    [self.controlView zf_playerPlayBtnState:YES];
    if (self.status == BCCPlayerStatusPause) { self.status = BCCPlayerStatusPlaying; }
//    self.isPauseByUser = NO;
    [self.player play];
}

/**
 * 暂停
 */
- (void)pause {
//    [self.controlView zf_playerPlayBtnState:NO];
    if (self.status == BCCPlayerStatusPlaying) { self.status = BCCPlayerStatusPause;}
//    self.isPauseByUser = YES;
    [self.player pause];
}

#pragma mark - player methods

- (void)seekToTime:(NSInteger)dragedSeconds completionHandler:(void (^)(BOOL finished))completionHandler {
    if (self.player.currentItem.status == AVPlayerItemStatusReadyToPlay) {
        // seekTime:completionHandler:不能精确定位
        // 如果需要精确定位，可以使用seekToTime:toleranceBefore:toleranceAfter:completionHandler:
        // 转换成CMTime才能给player来控制播放进度
//        [self.controlView zf_playerActivity:YES];
        [self.player pause];
        CMTime dragedCMTime = CMTimeMake(dragedSeconds, 1); //kCMTimeZero
        @weakify(self)
        [self.player seekToTime:dragedCMTime toleranceBefore:CMTimeMake(1,1) toleranceAfter:CMTimeMake(1,1) completionHandler:^(BOOL finished) {
            @strongify(self)
            // 视频跳转回调
            if (completionHandler) { completionHandler(finished); }
            [self.player play];
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
    // playbackBufferEmpty会反复进入，因此在bufferingOneSecond延时播放执行完之前再调用bufferingSomeSecond都忽略
    __block BOOL isBuffering = NO;
    if (isBuffering) return;
    isBuffering = YES;
    
    // 需要先暂停一小会之后再播放，否则网络状况不好的时候时间在走，声音播放不出来
    [self.player pause];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        // 如果此时用户已经暂停了，则不再需要开启播放了
//        if (self.isPauseByUser) {
//            isBuffering = NO;
//            return;
//        }
        
        [self play];
        // 如果执行了play还是没有播放则说明还没有缓存好，则再次缓存一段时间
        isBuffering = NO;
        if (!self.playerItem.isPlaybackLikelyToKeepUp) { [self bufferingSomeSeconds]; }
        
    });
}

- (void)addTimerObserve {

    @weakify(self);
    self.timeObserve = [self.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(1, NSEC_PER_SEC)
                                                                 queue:nil
                                                            usingBlock:^(CMTime time){
        @strongify(self)
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

- (void)previewVedioInSamllWindown:(CMTime)previewAtTime {
    [self.imageGenerator cancelAllCGImageGeneration];
    self.imageGenerator.appliesPreferredTrackTransform = YES;
    self.imageGenerator.maximumSize = CGSizeMake(100, 56);
    AVAssetImageGeneratorCompletionHandler handler = ^(CMTime requestedTime, CGImageRef im, CMTime actualTime, AVAssetImageGeneratorResult result, NSError *error){
        NSLog(@"%zd",result);
        if (result != AVAssetImageGeneratorSucceeded) {
            dispatch_async(dispatch_get_main_queue(), ^{
//                [controlView zf_playerDraggedTime:dragedSeconds sliderImage:self.thumbImg ? : ZFPlayerImage(@"ZFPlayer_loading_bgView")];
            });
        } else {
//            self.thumbImg = [UIImage imageWithCGImage:im];
            dispatch_async(dispatch_get_main_queue(), ^{
//                [controlView zf_playerDraggedTime:dragedSeconds sliderImage:self.thumbImg ? : ZFPlayerImage(@"ZFPlayer_loading_bgView")];
            });
        }
    };
    [self.imageGenerator generateCGImagesAsynchronouslyForTimes:[NSArray arrayWithObject:[NSValue valueWithCMTime:previewAtTime]] completionHandler:handler];
}

- (void)switchPlayerViewFrame:(BOOL)toFullScreen {
    
}

- (void)togglePlayerViewFrame:(BOOL)fullScreen {
    
    UIInterfaceOrientation orientation = UIInterfaceOrientationPortrait;
    if (fullScreen) {
        orientation = UIInterfaceOrientationLandscapeRight;
    }
    // 获取到当前状态条的方向
    UIInterfaceOrientation currentOrientation = [UIApplication sharedApplication].statusBarOrientation;
    // 判断如果当前方向和要旋转的方向一致,那么不做任何操作
    if (currentOrientation == orientation) { return; }
    
    // 根据要旋转的方向,使用Masonry重新修改限制
    if (orientation != UIInterfaceOrientationPortrait) {//
        // 这个地方加判断是为了从全屏的一侧,直接到全屏的另一侧不用修改限制,否则会出错;
        if (currentOrientation == UIInterfaceOrientationPortrait) {
            [self removeFromSuperview];
   
            [[UIApplication sharedApplication].keyWindow addSubview:self];
            self.frame = [UIScreen mainScreen].bounds;
        }
    }
    // iOS6.0之后,设置状态条的方法能使用的前提是shouldAutorotate为NO,也就是说这个视图控制器内,旋转要关掉;
    // 也就是说在实现这个方法的时候-(BOOL)shouldAutorotate返回值要为NO
    [[UIApplication sharedApplication] setStatusBarOrientation:orientation animated:NO];
    // 获取旋转状态条需要的时间:
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.3];
    // 更改了状态条的方向,但是设备方向UIInterfaceOrientation还是正方向的,这就要设置给你播放视频的视图的方向设置旋转
    // 给你的播放视频的view视图设置旋转
    self.transform = CGAffineTransformIdentity;
    self.transform = [self transformRotationAngle];
    // 开始旋转
    [UIView commitAnimations];
    
}

- (CGAffineTransform)transformRotationAngle {
    // 状态条的方向已经设置过,所以这个就是你想要旋转的方向
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    // 根据要进行旋转的方向来计算旋转的角度
    if (orientation == UIInterfaceOrientationPortrait) {
        return CGAffineTransformIdentity;
    } else if (orientation == UIInterfaceOrientationLandscapeLeft){
        return CGAffineTransformMakeRotation(-M_PI_2);
    } else if(orientation == UIInterfaceOrientationLandscapeRight){
        return CGAffineTransformMakeRotation(M_PI_2);
    }
    return CGAffineTransformIdentity;
}

#pragma mark - setters

- (void)setStatus:(BCCPlayerStatus)status {
    [self willChangeValueForKey:@"status"];
    _status = status;
    [self didChangeValueForKey:@"status"];
}


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
