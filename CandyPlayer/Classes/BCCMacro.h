//
//  BCCMacro.h
//  CandyPlayer-CandyPlayer
//
//  Created by 陈修武 on 2017/11/1.
//

#ifndef BCCMacro_h
#define BCCMacro_h

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

#define ScreenSize  UIScreen.mainScreen.bounds.size

#define IPHONEX     (MAX(ScreenSize.width, ScreenSize.height) == 812)

#endif /* BCCMacro_h */
