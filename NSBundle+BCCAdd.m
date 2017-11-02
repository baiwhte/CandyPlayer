//
//  NSBundle+BCCAdd.m
//  CandyPlayer
//
//  Created by 陈修武 on 2017/11/1.
//

#import "NSBundle+BCCAdd.h"

@implementation NSBundle (BCCAdd)

+ (NSBundle *)bcc_assetsPickerBundle {
    return [NSBundle bundleWithPath:[NSBundle bcc_assetsPickerBundlePath]];
}

+ (NSString *)bcc_assetsPickerBundlePath  {
    return [[NSBundle bundleForClass:NSClassFromString(@"BCCControlView")]
            pathForResource:@"CandyPlayer" ofType:@"bundle"];
}

@end
