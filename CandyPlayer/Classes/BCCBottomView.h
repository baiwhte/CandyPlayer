//
//  BCCBottomView.h
//  CandyPlayer
//
//  Created by 陈修武 on 2017/9/25.
//  Copyright © 2017年 baiwhte. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RACCommand;
@class RACReplaySubject;

@interface BCCBottomView : UIView

@property (nonatomic, assign) BOOL playOrPause;
@property (nonatomic, assign) BOOL fullScreen;

@property (nonatomic, strong, readonly) RACCommand *playCommand;

@property (nonatomic, strong, readonly) RACCommand *fullScreenCommand;

@property (nonatomic, strong, readonly) RACReplaySubject *subject;

@property (nonatomic, strong) NSString *currentTime;
@property (nonatomic, strong) NSString *totalTime;
@property (nonatomic, assign) CGFloat  sliderValue;
@property (nonatomic, assign) CGFloat  progressViewValue;

@end
