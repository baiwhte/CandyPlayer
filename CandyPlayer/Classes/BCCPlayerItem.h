//
//  BCCPlayerItem.h
//  CandyPlayer
//
//  Created by 陈修武 on 2017/9/22.
//  Copyright © 2017年 baiwhte. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BCCPlayerItem : NSObject

/*! 播放地址  */
//@property (nonatomic, strong) NSString *URLString;
@property (nonatomic, strong) NSURL    *vedioURL;

/** 视频标题 */
@property (nonatomic, strong) NSString *title;

/** 视频封面本地图片 */
@property (nonatomic, strong) NSString *placeholder;
/**
 * 视频封面网络图片url
 * 如果和本地图片同时设置，则忽略本地图片，显示网络图片
 */
@property (nonatomic, strong) NSString *placeholderImageURLString;

/** 视频开始播放秒数(默认0) */
@property (nonatomic, assign) NSInteger    seekTime;

@end
