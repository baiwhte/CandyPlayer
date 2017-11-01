//
//  BCCControlView.h
//  CandyPlayer
//
//  Created by 陈修武 on 2017/9/22.
//  Copyright © 2017年 baiwhte. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BCCPlayerView;
@class RACReplaySubject;

@interface BCCControlView : UIView

@property (nonatomic, weak) BCCPlayerView *playerView;

@property (nonatomic, strong) RACReplaySubject *sliderSubject;

@property (nonatomic, assign) Float64 currentTime;
@property (nonatomic, assign) CGFloat duration;

@property (nonatomic, assign) CGFloat bufferValue;

@end
