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
/*! player item  */
#import "BCCPlayerItem.h"

/*! apple framework  */
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>

/*! three lib  */
#import <Masonry/Masonry.h>
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

@property (nonatomic, strong) BCCPlayerItem          *playResItem;
/*! 重置订阅信号，若为YES表示不能接收next的值  */
@property (nonatomic, assign) BOOL                   resetSignal;

@property(nonatomic, readwrite) BCCPlayerStatus      status;

@property (nonatomic, assign) NSInteger              seekTime;
@property (nonatomic, assign) BOOL                   localVedio;
@property (nonatomic, assign) BOOL                   dragging;

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
    
    [self.controlView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(UIEdgeInsetsZero);
    }];
    
    [self.playbackView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(UIEdgeInsetsZero);
    }];
}

- (void)initialize {
    [self addSubview:self.controlView];
    
    self.controlView.playerView = self;
    @weakify(self)
    [self.controlView.sliderSubject subscribeNext:^(NSNumber *number) {
        @strongify(self)
        if ([number isKindOfClass:NSClassFromString(@"__NSCFBoolean")]) {
            self.dragging = number.boolValue;
        } else {
            
        }
    }];
}

- (void)resetPlayer {
    self.resetSignal = YES;
    if (self.timeObserve) {
        [self.player removeTimeObserver:self.timeObserve];
        self.timeObserve = nil;
    }
    [self.player replaceCurrentItemWithPlayerItem:nil];
    self.imageGenerator = nil;
    self.player = nil;
    self.controlView   = nil;
}

- (void)playbackVideo {
    _resetSignal  = NO;
    self.urlAsset = [AVURLAsset assetWithURL:self.playResItem.vedioURL];
    self.playerItem = [AVPlayerItem playerItemWithAsset:self.urlAsset];
    
    RACReplaySubject *subject = [RACReplaySubject subject];
    [RACObserve(self, resetSignal) subscribeNext:^(NSNumber *reset) {
        if (reset.boolValue) {
            [subject sendCompleted];
        }
    }];
    
    @weakify(self)
    [[RACObserve(self.playerItem, status)
      takeUntil:subject]
     subscribeNext:^(NSNumber *status) {
         @strongify(self)
         if ([status integerValue] == AVPlayerItemStatusReadyToPlay) {
             [self setNeedsLayout];
             [self layoutIfNeeded];
             // 添加playerLayer到self.layer
//             [self.layer insertSublayer:self.playerLayer atIndex:0];
             self.status = BCCPlayerStatusPlaying;
            
             if (self.seekTime) {
                 [self seekToTime:self.seekTime completionHandler:nil];
             }
//             self.player.muted = self.mute;
         } else if ([status integerValue] == AVPlayerItemStatusFailed) {
             self.status = BCCPlayerStatusFailed;
         }

    }];
    
    [[RACObserve(self.playerItem, loadedTimeRanges)
      takeUntil:subject]
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
      takeUntil:subject]
     subscribeNext:^(id  _Nullable x) {
         @strongify(self)
         // 当缓冲是空的时候
         if (self.playerItem.playbackBufferEmpty) {
             self.status = BCCPlayerStatusBuffering;
             [self bufferingSomeSeconds];
         }
    }];
    
    [[RACObserve(self.playerItem, playbackLikelyToKeepUp)
      takeUntil:subject]
     subscribeNext:^(id  _Nullable x) {
         // 当缓冲好的时候
         if (self.playerItem.playbackLikelyToKeepUp &&
             self.status == BCCPlayerStatusBuffering){
             self.status = BCCPlayerStatusPlaying;
         }
    }];
    
    [[[[NSNotificationCenter defaultCenter] rac_addObserverForName:AVPlayerItemDidPlayToEndTimeNotification
                                                            object:self.playerItem]
      takeUntil:subject]
     subscribeNext:^(NSNotification * notification) {
         @strongify(self)
         self.status = BCCPlayerStatusStopped;
     }];
    
    self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
    
    /* Observe the AVPlayer "currentItem" property to find out when any
     AVPlayer replaceCurrentItemWithPlayerItem: replacement will/did
     occur.*/
    [[RACObserve(self.player, currentItem) takeUntil:subject] subscribeNext:^(AVPlayerItem *playerItem) {
        @strongify(self)
        NSLog(@"currentItem:%@", playerItem);
        if (playerItem == nil) {
            return ;
        }
        [self.playbackView setPlayer:self.player];
        [self.playbackView setVideoFillMode:AVLayerVideoGravityResizeAspect];
    }];

    [[RACObserve(self.player, rate) takeUntil:subject] subscribeNext:^(NSNumber *rate) {
        NSLog(@"rate:%@", rate);
    }];
}

- (void)addApplicationNotification:(RACReplaySubject *)subject {
    [[[[NSNotificationCenter defaultCenter] rac_addObserverForName:UIApplicationWillResignActiveNotification object:nil]
     takeUntil:subject]
     subscribeNext:^(NSNotification * notification) {
         
     }];
    
    [[[[NSNotificationCenter defaultCenter] rac_addObserverForName:UIApplicationDidBecomeActiveNotification object:nil]
     takeUntil:self.rac_willDeallocSignal]
     subscribeNext:^(NSNotification * notification) {
         
     }];
    
    // 监测设备方向
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[[[NSNotificationCenter defaultCenter] rac_addObserverForName:UIDeviceOrientationDidChangeNotification object:nil]
     takeUntil:subject]
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
    _playResItem = playerItem;
    [self playbackVideo];
}

/**
 *  播放
 */
- (void)play {
//    [self.controlView zf_playerPlayBtnState:YES];
    if (self.status == BCCPlayerStatusPause) { self.status = BCCPlayerStatusPlaying; }
//    self.isPauseByUser = NO;
    [_player play];
}

/**
 * 暂停
 */
- (void)pause {
//    [self.controlView zf_playerPlayBtnState:NO];
    if (self.status == BCCPlayerStatusPlaying) { self.status = BCCPlayerStatusPause;}
//    self.isPauseByUser = YES;
    [_player pause];
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
//            [weakSelf.controlView zf_playerActivity:NO];
            // 视频跳转回调
            if (completionHandler) { completionHandler(finished); }
            [self.player play];
            self.seekTime = 0;
//            weakSelf.isDragged = NO;
            // 结束滑动
//            [weakSelf.controlView zf_playerDraggedEnd];
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

- (void)addTimer {
//    CMTime playerDuration = [self playerItemDuration];
//    if (CMTIME_IS_INVALID(playerDuration)) {
//        return;
//    }
//    double duration = CMTimeGetSeconds(playerDuration);
//    if (!isfinite(duration)) {
//        return;
//    }
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
            self.controlView.currentTime = currentTime;
            self.controlView.duration    = totalTime;
//            CGFloat value         = CMTimeGetSeconds([currentItem currentTime]) / totalTime;
//            [weakSelf.controlView zf_playerCurrentTime:currentTime totalTime:totalTime sliderValue:value];
        }
    }];
}

- (void)removeTime {
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

@end
