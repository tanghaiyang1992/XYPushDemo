//
//  XYPushManage.m
//  XYPushDemo
//
//  Created by tanghaiyang on 2017/8/28.
//  Copyright © 2017年 tanghaiyang. All rights reserved.
//

#import "XYPushManage.h"
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
#import <UserNotifications/UserNotifications.h>
#endif

@implementation XYPushManage<UNUserNotificationCenterDelegate>

#pragma mark -- 注册个推SDK
- (void)mm_application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // [ GTSdk ]：是否允许APP后台运行
    //    [GeTuiSdk runBackgroundEnable:YES];
    // [ GTSdk ]：是否运行电子围栏Lbs功能和是否SDK主动请求用户定位
    [GeTuiSdk lbsLocationEnable:YES andUserVerify:YES];
    // [ GTSdk ]：自定义渠道
    [GeTuiSdk setChannelId:@"GT-Channel"];
    // [ GTSdk ]：使用APPID/APPKEY/APPSECRENT创建个推实例
    [GeTuiSdk startSdkWithAppId:GetuiAppID appKey:GetuiAppKey appSecret:GetuiAppSecret delegate:self];
    // 注册APNs - custom method - 开发者自定义的方法
    [self registerRemoteNotification];
    if (launchOptions[UIApplicationLaunchOptionsLocalNotificationKey]) {
        // 当被杀死状态收到本地通知时执行的跳转代码
        UILocalNotification *notification = [launchOptions objectForKey:UIApplicationLaunchOptionsLocalNotificationKey];
        NSDictionary *infoDict = [mnResource dictionaryWithJsonString:notification.userInfo[@"info"]];
        if (self.delegate && [self.delegate respondsToSelector:@selector(XYPushManageDelagateWhenReceivePushInfo:)]) {
            [self.delegate XYPushManageDelagateWhenReceivePushInfo:infoDict];
        }
        NSLog(@"这个方法什么时候会走");
    }
}
// 在iOS 10 以前，为处理 APNs 通知点击事件，统计有效用户点击数，需在AppDelegate.m里的didReceiveRemoteNotification回调方法中调用个推SDK统计接口：
- (void)mm_application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler
{
    NSLog(@"在iOS 10 以前，为处理 APNs 通知点击事件");
    // 处理APNs代码，通过userInfo可以取到推送的信息（包括内容，角标，自定义参数等）。如果需要弹窗等其他操作，则需要自行编码。
    [GeTuiSdk setBadge:1];
    //如果需要角标显示需要调用系统方法设置
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:1];
    // 处理APN
    [GeTuiSdk handleRemoteNotification:userInfo];
    completionHandler(UIBackgroundFetchResultNewData);
}

// 对于iOS 10 及以后版本，为处理 APNs 通知点击，统计有效用户点击数，需先添加 UNUserNotificationCenterDelegate，然后在AppDelegate.m的 didReceiveNotificationResponse回调方法中调用个推SDK统计接口：
#pragma mark - iOS 10中收到推送消息
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
//  iOS 10: App在前台获取到通知
- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler {
    NSLog(@"iOS 10: App在前台获取到通知");
    NSLog(@"willPresentNotification：%@", notification.request.content.userInfo);
    // 根据APP需要，判断是否要提示用户Badge、Sound、Alert
    completionHandler(UNNotificationPresentationOptionBadge | UNNotificationPresentationOptionSound | UNNotificationPresentationOptionAlert);
}

//  iOS 10: 点击通知进入App时触发，在该方法内统计有效用户点击数
- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)())completionHandler {
    
    NSLog(@"iOS 10: 点击通知进入App时触发，在该方法内统计有效用户点击数");
    NSLog(@"didReceiveNotification：%@", response.notification.request.content.userInfo);
    [GeTuiSdk setBadge:0];
    
    NSDictionary *userInfo = response.notification.request.content.userInfo;
    // [ GTSdk ]：将收到的APNs信息传给个推统计
    [GeTuiSdk handleRemoteNotification:response.notification.request.content.userInfo];
    completionHandler();
}
#endif


#pragma mark - ios 10 系统在后台会走这里
- (void)mm_application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    NSLog(@"ios 10 系统在后台会走这里");
    [GeTuiSdk setBadge:0];
    //如果需要角标显示需要调用系统方法设置
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
}

- (void)mm_application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    [GeTuiSdk resume];
}

//当 SDK 在线时（即 App 在前台运行时）进行消息推送，该消息将直接通过个推通道发送给 App ，通常这种方式比通过APNs发送来得更及时更稳定；当 SDK 离线时（即停止 SDK 或 App 后台运行 或 App 停止状态时）进行消息推送，个推平台会给苹果 APNs 推送消息，同时保存个推通道的离线消息，当 SDK 重新上线后，个推平台会重新推送所有离线的消息。
//APP 可以通过[GeTuiSdkDelegate GeTuiSdkDidReceivePayloadData]回调方法获取透传消息，其中payloadData参数为透传消息数据，offLine参数则表明该条消息是否为离线消息。示例代码如下：
/** SDK收到透传消息回调 */
- (void)GeTuiSdkDidReceivePayloadData:(NSData *)payloadData andTaskId:(NSString *)taskId andMsgId:(NSString *)msgId andOffLine:(BOOL)offLine fromGtAppId:(NSString *)appId {
    NSLog(@"/** SDK收到透传消息回调 */");
    
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:1];
    // [4]: 收到个推消息
    [GeTuiSdk sendFeedbackMessage:90001 andTaskId:taskId andMsgId:msgId];
    
}

#pragma mark - 用户通知(推送) _自定义方法
/** 注册远程通知 */
- (void)registerRemoteNotification {
    /*
     警告：Xcode8的需要手动开启“TARGETS -> Capabilities -> Push Notifications”
     */
    
    /*
     警告：该方法需要开发者自定义，以下代码根据APP支持的iOS系统不同，代码可以对应修改。
     以下为演示代码，注意根据实际需要修改，注意测试支持的iOS系统都能获取到DeviceToken
     */
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 10.0) {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0 // Xcode 8编译会调用
        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        center.delegate = self;
        // 设置
        [self addCustomUICategory];
        [center requestAuthorizationWithOptions:(UNAuthorizationOptionBadge | UNAuthorizationOptionSound | UNAuthorizationOptionAlert | UNAuthorizationOptionCarPlay) completionHandler:^(BOOL granted, NSError *_Nullable error) {
            if (!error) {
                NSLog(@"request authorization succeeded!");
            }
        }];
        
        [[UIApplication sharedApplication] registerForRemoteNotifications];
#else // Xcode 7编译会调用
        UIUserNotificationType types = (UIUserNotificationTypeAlert | UIUserNotificationTypeSound | UIUserNotificationTypeBadge);
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:types categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
        [[UIApplication sharedApplication] registerForRemoteNotifications];
#endif
    } else if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0) {
        UIUserNotificationType types = (UIUserNotificationTypeAlert | UIUserNotificationTypeSound | UIUserNotificationTypeBadge);
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:types categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    } else {
        
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        
        // 这里写出现警告的代码
        UIRemoteNotificationType apn_type = (UIRemoteNotificationType)(UIRemoteNotificationTypeAlert |
                                                                       UIRemoteNotificationTypeSound |
                                                                       UIRemoteNotificationTypeBadge);
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:apn_type];
        
#pragma clang diagnostic pop
        
    }
}

- (void)addCustomUICategory
{
    // --- openAction
    UNNotificationAction *openAction = [UNNotificationAction actionWithIdentifier:@"action-open" title:@"查看" options:UNNotificationActionOptionForeground];
    //
    UNNotificationAction *cancelAction = [UNNotificationAction actionWithIdentifier:@"action-cancel" title:@"不感兴趣" options:UNNotificationActionOptionAuthenticationRequired];
    
    // --- likeAction
    //    UNNotificationAction *likeAction = [UNNotificationAction actionWithIdentifier:@"action-like" title:@"赞" options:UNNotificationActionOptionAuthenticationRequired];
    //    // --- collectAction
    //    UNNotificationAction *collectAction = [UNNotificationAction actionWithIdentifier:@"action-collect" title:@"收藏" options:UNNotificationActionOptionDestructive];
    //    // --- commentAction
    //    UNTextInputNotificationAction *commentAction = [UNTextInputNotificationAction actionWithIdentifier:@"action-comment" title:@"评论" options:UNNotificationActionOptionDestructive textInputButtonTitle:@"发送" textInputPlaceholder:@"输入你的评论"];
    
    // --- 组装
    UNNotificationCategory *category = [UNNotificationCategory categoryWithIdentifier:@"category2" actions:@[openAction, cancelAction] intentIdentifiers:@[] options:UNNotificationCategoryOptionCustomDismissAction];
    [[UNUserNotificationCenter currentNotificationCenter] setNotificationCategories:[NSSet setWithObjects:category, nil]];
}


#pragma mark - 远程通知(推送)回调
/** 远程通知注册成功委托 */
- (void)mm_application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    NSString *token = [[deviceToken description] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
    token = [token stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSLog(@"\n>>>[DeviceToken Success]:%@\n\n", token)
    // [3]:向个推服务器注册deviceToken
    [GeTuiSdk registerDeviceToken:token];
    
}

- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    /// Background Fetch 恢复SDK 运行
    [GeTuiSdk resume];
    completionHandler(UIBackgroundFetchResultNewData);
}

/** SDK启动成功返回cid */
- (void)GeTuiSdkDidRegisterClient:(NSString *)clientId {
    // [4-EXT-1]: 个推SDK已注册，返回clientId
    NSLog(@"\n>>>[GeTuiSdk RegisterClient]:%@\n\n", clientId);
    KsetUserValueByParaName(clientId, GETUIClientId);
}

/** SDK遇到错误回调 */
- (void)GeTuiSdkDidOccurError:(NSError *)error {
    // [EXT]:个推错误报告，集成步骤发生的任何错误都在这里通知，如果集成后，无法正常收到消息，查看这里的通知。
    NSLog(@"\n>>>[GexinSdk error]:%@\n\n", [error localizedDescription]);
}

#pragma mark - 用户通知(推送)回调 _IOS 8.0以上使用
/** 已登记用户通知 */
- (void)mm_application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings
{
    // 注册远程通知（推送）
    [application registerForRemoteNotifications];
}

#pragma mark -- App处于活跃状态 －－BecomeActive
- (void)mm_applicationDidBecomeActive:(UIApplication *)application
{
    _num = 0;
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
}

/** 远程通知注册失败委托 */
- (void)mm_application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    NSLog(@"远程通知注册失败委托\n>>>[DeviceToken Error]:%@\n\n", error.description);
}

/** SDK收到sendMessage消息回调 */
- (void)GeTuiSdkDidSendMessage:(NSString *)messageId result:(int)result {
    // [4-EXT]:发送上行消息结果反馈
    NSString *msg = [NSString stringWithFormat:@"sendmessage=%@,result=%d", messageId, result];
    NSLog(@"\n>>>[GexinSdk DidSendMessage]:%@\n\n", msg);
}

/** SDK运行状态通知 */
- (void)GeTuiSDkDidNotifySdkState:(SdkStatus)aStatus {
    // [EXT]:通知SDK运行状态
    NSLog(@"\n>>>[GexinSdk SdkState]:%u\n\n", aStatus);
}

/** SDK设置推送模式回调 */
- (void)GeTuiSdkDidSetPushMode:(BOOL)isModeOff error:(NSError *)error {
    if (error) {
        return;
    }
}

@end
