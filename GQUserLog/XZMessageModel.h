//
//  XZMessageModel.h
//  GQUserLog
//
//  Created by qing on 2017/9/22.
//  Copyright © 2017年 YCC. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  操作日志type
 */
typedef NS_ENUM(NSInteger, XZ_USER_LOG_ACTION_TYPE)
{
    
    XZ_USER_LOG_ACTION_TYPE_LogLevel  = 0,// 修改日志等级
    XZ_USER_LOG_ACTION_TYPE_GetLog    = 1,// 获取用户日志
};

/**
 *  用户打印日志等级
 */
typedef NS_ENUM(NSInteger, XZ_USER_LOG_LEVEL)
{
    
    XZ_USER_LOG_LEVEL_Error    = 1,// error
    XZ_USER_LOG_LEVEL_Warning  = 2,// error、Warning
    XZ_USER_LOG_LEVEL_Info     = 3,// error、Warning、Info
    XZ_USER_LOG_LEVEL_Debug    = 4,// error、Warning、Info、Debug
    XZ_USER_LOG_LEVEL_Verbose  = 5,// error、Warning、Info、Debug、Verbose
};

@interface XZMessageModel : NSObject

//消息体
@property (nonatomic, strong) id content;

@end


#pragma mark - 用户日志消息 16100

@interface XZUserLogMsgModel : NSObject

@property (nonatomic, assign) XZ_USER_LOG_ACTION_TYPE actionType;
@property (nonatomic, assign) XZ_USER_LOG_LEVEL logLevel;//
@property (nonatomic, assign) long long timestamp;
/**日志文件压缩密码 */
@property (nonatomic, strong) NSString *compressPwd;

@end
