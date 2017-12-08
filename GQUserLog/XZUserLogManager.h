//
//  XZUserLogManager.h
//  Xiezhu
//
//  Created by qing on 2017/8/28.
//  Copyright © 2017年 GouLiao11. All rights reserved.
//

#import <Foundation/Foundation.h>

@class XZMessageModel;
@interface XZUserLogManager : NSObject

+ (instancetype)shareInstance;

+ (void)releaseInstance;

/**
 *   接收到服务器下发的日志消息
 *
 */
- (void)adjustLogLevelWithMsgModel:(XZMessageModel *)msgModel;

- (void)deleteOutOfDateLog;

- (NSInteger)getLogLevel;

@end
