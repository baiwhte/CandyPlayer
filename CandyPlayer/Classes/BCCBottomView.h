//
//  BCCBottomView.h
//  CandyPlayer
//
//  Created by baiwhte on 2017/9/25.
//  Copyright © 2017年 baiwhte. All rights reserved.
//

#import "BCCBaseView.h"

@interface BCCBottomView : BCCBaseView

@property (nonatomic, assign) BOOL fullScreen;

@property (nonatomic, assign) BOOL isPlayback;
/** 当前时间 */
@property (nonatomic, assign) Float64 currentTime;
/** 视频总时间 */
@property (nonatomic, assign) Float64 duration;
/** 缓冲时间 */
@property (nonatomic, assign) CGFloat   bufferValue;

@property (nonatomic, assign) BOOL hideScreenButton;

@property (nonatomic, assign, readonly) BOOL isDragging;

@end
