//
//  BCCPlayerView.h
//  CandyPlayer
//
//  Created by 陈修武 on 2017/9/22.
//  Copyright © 2017年 baiwhte. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, BCCPlayerStatus) {
    BCCPlayerStatusFailed,     // 播放失败
    BCCPlayerStatusBuffering,  // 缓冲中
    BCCPlayerStatusPlaying,    // 播放中
    BCCPlayerStatusStopped,    // 停止播放
    BCCPlayerStatusPause       // 暂停播放
};

@class BCCPlayerItem;

@interface BCCPlayerView : UIView

@property (nonatomic, assign) BOOL allowPreview;

/*!  Device is horizontal screen 是否为横屏 */
@property(nonatomic, readonly, getter=isHorizontalScreen) BOOL horizontalScreen;

@property(nonatomic, readonly) BCCPlayerStatus status;

- (void)playbackWithPlyerItem:(BCCPlayerItem *)playerItem inContainerView:(UIView *)containerView;

@end
