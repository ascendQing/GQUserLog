//
//  XZUserLogManager.m
//  Xiezhu
//
//  Created by qing on 2017/8/28.
//  Copyright © 2017年 GouLiao11. All rights reserved.
//

#import "XZUserLogManager.h"
#import "XZMessageModel.h"
#import "XZDynamicLogLevel.h"
#import <SSZipArchive.h>
#import "XZUserKVStoreManage.h"

@interface XZUserLogManager ()

/**<#注释#> */
@property (nonatomic, assign) NSInteger logLevel;

@end

static XZUserLogManager *instance = nil;
@implementation XZUserLogManager

+ (instancetype)shareInstance {
    
    @synchronized(self) {
        if (!instance) {
            instance = [[XZUserLogManager alloc] init];
        }
    }
    return instance;
}

+ (void)releaseInstance {
    
    if(instance)
    {
        instance.logLevel = 0;
        instance = nil;
    }
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        //获取数据库中存的用户日志等级
        self.logLevel = [[[XZUserKVStoreManage shareInstance] getNumberWithTableName:@"UserLogLevel"
                                                                                 key:@"UserLogLevelKey"] integerValue];
    }
    return self;
}

/**
 *   接收到服务器下发的日志消息
 *
 */
- (void)adjustLogLevelWithMsgModel:(XZMessageModel *)msgModel {
    
    //解析出来日志消息体
    XZUserLogMsgModel *userLogModel = msgModel.content;
    
    switch (userLogModel.actionType) {
        case XZ_USER_LOG_ACTION_TYPE_LogLevel: { // 修改用户日志等级
            
            self.logLevel = userLogModel.logLevel;//先改变Log等级
            [XZDynamicLogLevel ddSetLogLevel:(DDLogLevel)userLogModel.logLevel];//存数据库
            break;
        }
        case XZ_USER_LOG_ACTION_TYPE_GetLog: { // 上传日志
            
            //获取日志本地路径
            NSString *txtPath = [NSString stringWithFormat:@"%@/Logs/%@/",DOCUMENTS_PATH,oyToStr(USERID)];
            
            //获取压缩用户日志到本地的路径
            NSString *zipPath = [NSString stringWithFormat:@"%@/Logs",DOCUMENTS_PATH];
            NSString *zipName = [NSString stringWithFormat:@"%@%lld.zip",oyToStr(USERID),[self getCurrentDate]];
            zipPath = [zipPath stringByAppendingPathComponent:zipName];
            
            //压缩用户日志
            BOOL success = [SSZipArchive createZipFileAtPath:zipPath withContentsOfDirectory:txtPath withPassword:userLogModel.compressPwd];
            
            if (success) {
                
                // 在这里上传
                
            }
            break;
        }
        default:
            break;
    }
    
}

#pragma mark - delete out of date user log
- (void)deleteOutOfDateLog {
    
    NSString *logPath = [NSString stringWithFormat:@"%@/Logs/%@/",DOCUMENTS_PATH,oyToStr(USERID)];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    dateFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT+0800"];;
    //删除过期的日志
    NSDate *prevDate = [[NSDate date] dateByAddingTimeInterval:-60*60*24*3];
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:prevDate];
    [components setHour:0];
    [components setMinute:0];
    [components setSecond:0];
    //要删除三天以前的日志（0点开始）
    NSDate *delDate = [[NSCalendar currentCalendar] dateFromComponents:components];
    NSArray *logFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:logPath error:nil];
    
    //如果沙盒里面日志小于4份，就不要删除了，最少保留3天的
    if (logFiles.count < 4) {
        
        return;
    }
    
    for (NSString *file in logFiles)
    {
        NSString *fileName = [file stringByReplacingOccurrencesOfString:@".txt" withString:@""];
        fileName = [fileName stringByReplacingOccurrencesOfString:@"GQ_Log_" withString:@""];
        NSDate *fileDate = [dateFormatter dateFromString:fileName];
        if (nil == fileDate)
        {
            continue;
        }
        if (NSOrderedAscending == [fileDate compare:delDate])
        {
            [[NSFileManager defaultManager] removeItemAtPath:[logPath stringByAppendingString:file] error:nil];
        }
    }

}

/**
 *获得系统日期 13位（返回long）
 *return 当前日期
 */
- (long long)getCurrentDate
{
    
    NSDate *dat = [NSDate dateWithTimeIntervalSinceNow:0];
    NSTimeInterval now = [dat timeIntervalSince1970]*1000;
    return now;
}
    
    
- (NSInteger)getLogLevel {
    
    return self.logLevel;
}

@end
