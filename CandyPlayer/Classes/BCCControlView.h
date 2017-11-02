//
//  BCCControlView.h
//  CandyPlayer
//
//  Created by 陈修武 on 2017/9/22.
//  Copyright © 2017年 baiwhte. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RACReplaySubject;

@interface BCCControlView : UIView

@property (nonatomic, strong) RACReplaySubject *sliderSubject;

@property (nonatomic, assign) BOOL fullScreen;
@property (nonatomic, assign) BOOL isPlayback;
@property (nonatomic, assign) BOOL isBuffering;

@property (nonatomic, assign) Float64 currentTime;
@property (nonatomic, assign) Float64 duration;

@property (nonatomic, assign) CGFloat bufferValue;

@end
