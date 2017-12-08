//
//  XZLogFormatter.m
//  Xiezhu
//
//  Created by qing on 2017/8/25.
//  Copyright © 2017年 GouLiao11. All rights reserved.
//

#import "XZLogFormatter.h"

@implementation XZLogFormatter

/**
 *  这里的格式: log打印时间 -> log等级 -> app版本 -> 打印位置 -> log描述
 *
 */
- (NSString *)formatLogMessage:(DDLogMessage *)logMessage{
    NSMutableDictionary *logDict = [NSMutableDictionary dictionary];
    
    //取得文件名
    NSString *locationString;
    NSArray *parts = [logMessage->_file componentsSeparatedByString:@"/"];
    if ([parts count] > 0)
        locationString = [parts lastObject];
    if ([locationString length] == 0)
        locationString = @"No file";
    
    logDict[@"logTime"] = [self timestampToNSString:[self getCurrentDate] formatter:@"MM/dd HH:mm:ss"];
    logDict[@"logLevel"] = [self getLogLevelWithDDLogLevel:logMessage.flag];
    logDict[@"location"] = [NSString stringWithFormat:@"%@:%lu(%@)", locationString, (unsigned long)logMessage.line, logMessage.function];
    logDict[@"des"] = logMessage.message;
    // app版本
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString *app_Version = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
    
    NSString *logStr = [NSString stringWithFormat:@"%@ %@ version:%@ location:%@\nDes:%@\n",logDict[@"logTime"],logDict[@"logLevel"],app_Version,logDict[@"location"],logDict[@"des"]];

    return logStr;
}

- (NSString *)getLogLevelWithDDLogLevel:(DDLogFlag)level {
    
    NSString *logLevel = @"";
    
    switch (level) {
        case DDLogFlagError: {
            
            logLevel = @"[Error]";
            break;
        }
        case DDLogFlagWarning: {
            
            logLevel = @"[Warning]";
            break;
        }
        case DDLogFlagInfo: {
            
            logLevel = @"[Info]";
            break;
        }
        case DDLogFlagDebug: {
            
            logLevel = @"[Debug]";
            break;
        }
        case DDLogFlagVerbose: {
            
            logLevel = @"[Verbose]";
            break;
        }
        default:
            break;
    }
    
    return logLevel;
    
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

/**
 *  时间戳转指定格式的时间
 */
- (NSString *)timestampToNSString:(NSTimeInterval)timestampTmp formatter:(NSString *)formatter {
    
    NSDate *dateTmp = [NSDate dateWithTimeIntervalSince1970:timestampTmp / 1000];
    
    NSDateFormatter* dataFormatter = [[NSDateFormatter alloc] init];
    [dataFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dataFormatter setTimeStyle:NSDateFormatterShortStyle];
    [dataFormatter setDateFormat:formatter];
    
    NSString* string = [dataFormatter stringFromDate:dateTmp];
    
    return string;
}

@end
