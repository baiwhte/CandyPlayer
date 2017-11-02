//
//  UIImage+BCCAdd.h
//  Pods
//
//  Created by 陈修武 on 2017/11/1.
//

#import <UIKit/UIKit.h>

@interface UIImage (BCCAdd)

/**
 *  获取纯色图片
 *  @param color 颜色
 *  @param size  图片尺寸
 */
+ (UIImage *)bcc_imageWithColor:(UIColor *)color size:(CGSize)size;

/**
 *  获取圆角图片
 *  @param cornerRadius 圆角半径
 */
- (UIImage *)bcc_roundedCornerWithCornerRadius:(CGFloat)cornerRadius;

+ (UIImage *)bcc_imageNamed:(NSString *)name;

@end
