//
//  XZDynamicLogLevel.m
//  Xiezhu
//
//  Created by qing on 2017/8/28.
//  Copyright © 2017年 GouLiao11. All rights reserved.
//  这个类旨在动态调整log等级

#import "XZDynamicLogLevel.h"
#import "YTKKeyValueStore.h"
#import "XZUserKVStoreManage.h"
#import "XZUserLogManager.h"

#define XZ_USER_LOG_LEVEL_DB_KEY  @"UserLogLevelKey"
#define XZ_USER_LOG_LEVEL_DB_NAME @"UserLogLevel"
@interface XZDynamicLogLevel ()

@end

@implementation XZDynamicLogLevel

/**
 *  每次打印log会获取log等级
 *
 */
+ (DDLogLevel)ddLogLevel {
    
    NSInteger logLevel = [[XZUserLogManager shareInstance] getLogLevel];
    
    if (logLevel == 0) {
        
        #if DEBUG
                return DDLogLevelVerbose;
        #else
                return DDLogLevelWarning;
        #endif
        
    } else {
        
        if (logLevel == 1) {
            
            return DDLogLevelError;
        }
        else if (logLevel == 2) {
            
            return DDLogLevelWarning;
        }
        else if (logLevel == 3) {
            
            return DDLogLevelInfo;
        }
        else if (logLevel == 4) {
            
            return DDLogLevelDebug;
        }
        else {
            
            return DDLogLevelVerbose;
        }
    }
     
}

+ (void)ddSetLogLevel:(DDLogLevel)level {
    
    [[XZUserKVStoreManage shareInstance] saveNumberWithNumber:@(level)
                                                    TableName:XZ_USER_LOG_LEVEL_DB_NAME
                                                          key:XZ_USER_LOG_LEVEL_DB_KEY];
}

@end
