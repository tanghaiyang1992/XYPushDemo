//
//  XYPushManage.h
//  XYPushDemo
//
//  Created by tanghaiyang on 2017/8/28.
//  Copyright © 2017年 tanghaiyang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GeTuiSdk.h"// -----个推
#import "AppDelegate.h"

@protocol XYPushManageDelagate <NSObject>
@optional
- (void)XYPushManageDelagateWhenReceivePushInfo:(NSDictionary *)pushInfo;
@end

@interface XYPushManage : NSObject<GeTuiSdkDelegate>

@property (nonatomic,weak)id<XYPushManageDelagate>delegate;

// 注册个推SDK
- (void)mm_application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions;

// App处于活跃状态 －－BecomeActive
- (void)mm_applicationDidBecomeActive:(UIApplication *)application;

// 远程通知(推送)回调
- (void)mm_application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken;

// APP运行中接收到通知(推送)处理
- (void)mm_application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo;

// App在后台会走这个方法
- (void)mm_application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler;

// 用户通知(推送)回调 _IOS 8.0以上使用
- (void)mm_application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings;

/** 远程通知注册失败委托 */
- (void)mm_application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error;

// Background Fetch 恢复SDK 运行
- (void)mm_application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler;

@end
