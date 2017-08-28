//
//  NotificationViewController.m
//  XYPushDemoNotificationViewController
//
//  Created by tanghaiyang on 2017/8/28.
//  Copyright © 2017年 tanghaiyang. All rights reserved.
//

#import "NotificationViewController.h"
#import <UserNotifications/UserNotifications.h>
#import <UserNotificationsUI/UserNotificationsUI.h>
#import <AVFoundation/AVFoundation.h>

@interface NotificationViewController () <UNNotificationContentExtension>

@property IBOutlet UILabel *label;
@property (nonatomic, strong) AVAudioPlayer *player;
@property (nonatomic, copy) void (^completion)(UNNotificationContentExtensionResponseOption option);
@end

@implementation NotificationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any required interface initialization here.
}

- (void)didReceiveNotification:(UNNotification *)notification {
    self.label.text = notification.request.content.body;
}

// 按钮的点击事件
- (void)didReceiveNotificationResponse:(UNNotificationResponse *)response completionHandler:(void (^)(UNNotificationContentExtensionResponseOption option))completion
{
    if ([response.actionIdentifier isEqualToString:@"action-open"]){ // 打开
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            completion(UNNotificationContentExtensionResponseOptionDismiss);
        });
    }
    else if ([response.actionIdentifier isEqualToString:@"action-cancel"]){ // 取消、不打开
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            completion(UNNotificationContentExtensionResponseOptionDismissAndForwardAction);
        });
    }
    else if ([response.actionIdentifier isEqualToString:@"action-like"]) {
        
        self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"like" ofType:@"m4a"]] error:nil];
        [self.player play];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.player stop];
            self.player = nil;
            completion(UNNotificationContentExtensionResponseOptionDismiss);
        });
    }
    else if ([response.actionIdentifier isEqualToString:@"action-collect"]){
        
        self.label.text = @"收藏成功~";
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            completion(UNNotificationContentExtensionResponseOptionDismiss);
        });
        
    }
    else if ([response.actionIdentifier isEqualToString:@"action-comment"]){
        self.label.text = [(UNTextInputNotificationResponse *)response userText];
    }
    
    //这里如果点击的action类型为UNNotificationActionOptionForeground，
    //则即使completion设置成Dismiss的，通知也不能消失
}


@end
