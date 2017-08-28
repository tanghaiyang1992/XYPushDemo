//
//  NotificationService.m
//  XYPushDemoNotificationService
//
//  Created by tanghaiyang on 2017/8/28.
//  Copyright © 2017年 tanghaiyang. All rights reserved.
//

#import "NotificationService.h"
#import "GeTuiExtSdk.h"

@interface NotificationService ()

@property (nonatomic, strong) void (^contentHandler)(UNNotificationContent *contentToDeliver);
@property (nonatomic, strong) UNMutableNotificationContent *bestAttemptContent;

@end

@implementation NotificationService

- (void)didReceiveNotificationRequest:(UNNotificationRequest *)request withContentHandler:(void (^)(UNNotificationContent * _Nonnull))contentHandler {
    self.contentHandler = contentHandler;
    self.bestAttemptContent = [request.content mutableCopy];
    // Modify the notification content here...
    NSDictionary *apsDic =  [[self dictionaryWithJsonString:self.bestAttemptContent.userInfo[@"payload"] ] objectForKey:@"aps"];
    self.bestAttemptContent.title = @"经济日报";
    self.bestAttemptContent.subtitle = [apsDic objectForKey:@"pushtopic"];
    self.bestAttemptContent.body = [NSString stringWithFormat:@"%@",[[[self.bestAttemptContent.userInfo objectForKey:@"aps"] objectForKey:@"alert"] objectForKey:@"body"]];
    // 附件
    NSString *imageUrl = [NSString stringWithFormat:@"%@",[apsDic objectForKey:@"pushimageurl"]];
    
    NSLog(@"userInfo-----%@",self.bestAttemptContent.userInfo);
    NSLog(@"alert-----%@",[[self.bestAttemptContent.userInfo objectForKey:@"aps"] objectForKey:@"alert"]);
    NSLog(@"apsDic-----%@",apsDic);
    
    // 这里添加一些点击事件，可以在收到通知的时候，添加，也可以在拦截通知的这个扩展中添加
    self.bestAttemptContent.categoryIdentifier = @"category2";
    
    if (!imageUrl.length){
        self.contentHandler(self.bestAttemptContent);
    }
    //  图片下载
    [self loadAttachmentForUrlString:imageUrl withType:@"jpg" completionHandle:^(UNNotificationAttachment *attach) {
        if (attach)
        {
            self.bestAttemptContent.attachments = [NSArray arrayWithObject:attach];
        }
        self.contentHandler(self.bestAttemptContent);
        //  个推的统计APNs到达情况
        [GeTuiExtSdk handelNotificationServiceRequest:request withComplete:^
         {
             self.contentHandler(self.bestAttemptContent); //展示推送的回调处理需要放到个推回执完成的回调中
         }];
    }];
}


- (void)serviceExtensionTimeWillExpire {
    // Called just before the extension will be terminated by the system.
    // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
    self.contentHandler(self.bestAttemptContent);
}


// 下载数据
- (void)loadAttachmentForUrlString:(NSString *)urlStr
                          withType:(NSString *)type
                  completionHandle:(void(^)(UNNotificationAttachment *attach))completionHandler
{
    __block UNNotificationAttachment *attachment = nil;
    NSURL *attachmentURL = [NSURL URLWithString:urlStr];
    NSString *fileExt = [self fileExtensionForMediaType:type];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    [[session downloadTaskWithURL:attachmentURL
                completionHandler:^(NSURL *temporaryFileLocation, NSURLResponse *response, NSError *error) {
                    if (error != nil){
                    }
                    else{
                        NSFileManager *fileManager = [NSFileManager defaultManager];
                        NSURL *localURL = [NSURL fileURLWithPath:[temporaryFileLocation.path stringByAppendingString:fileExt]];
                        [fileManager moveItemAtURL:temporaryFileLocation toURL:localURL error:&error];
                        NSError *attachmentError = nil;
                        attachment = [UNNotificationAttachment attachmentWithIdentifier:@"" URL:localURL options:nil error:&attachmentError];
                        if (attachmentError)
                        {
                        }
                    }
                    completionHandler(attachment);
                }] resume];
}

// 判断多媒体数据类型
- (NSString *)fileExtensionForMediaType:(NSString *)type {
    NSString *ext = type;
    if ([type isEqualToString:@"image"])
    {
        ext = @"jpg";
    }
    if ([type isEqualToString:@"video"])
    {
        ext = @"mp4";
    }
    if ([type isEqualToString:@"audio"])
    {
        ext = @"mp3";
    }
    return [@"." stringByAppendingString:ext];
}


- (NSDictionary *)dictionaryWithJsonString:(NSString *)jsonString {
    
    if (jsonString == nil) {
        
        return nil;
    }
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *err;
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData
                                                        options:NSJSONReadingMutableContainers
                                                          error:&err];
    if(err) {
        return nil;
    }
    return dic;
}


@end
