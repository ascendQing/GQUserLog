//
//  XZDynamicLogLevel.h
//  Xiezhu
//
//  Created by qing on 2017/8/28.
//  Copyright © 2017年 GouLiao11. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DDLog.h"

@interface XZDynamicLogLevel : NSObject<DDRegisteredDynamicLogging>

+ (DDLogLevel)ddLogLevel;

+ (void)ddSetLogLevel:(DDLogLevel)level;



@end
