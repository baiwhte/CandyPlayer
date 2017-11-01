//
//  BCCPlaybackView.m
//  CandyPlayer
//
//  Created by 陈修武 on 2017/9/22.
//  Copyright © 2017年 baiwhte. All rights reserved.
//

#import "BCCPlaybackView.h"
#import <AVFoundation/AVFoundation.h>

@implementation BCCPlaybackView

+ (Class)layerClass {
    return [AVPlayerLayer class];
}

- (AVPlayer *)player {
    return [(AVPlayerLayer*)[self layer] player];
}

- (void)setPlayer:(AVPlayer*)player {
    [(AVPlayerLayer*)[self layer] setPlayer:player];
}

/* Specifies how the video is displayed within a player layer’s bounds.
 (AVLayerVideoGravityResizeAspect is default) */
- (void)setVideoFillMode:(NSString *)fillMode {
    AVPlayerLayer *playerLayer = (AVPlayerLayer*)[self layer];
    playerLayer.videoGravity = fillMode;
}

@end
