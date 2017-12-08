//
//  XZUserKVStoreManage.m
//  Xiezhu
//
//  Created by qing on 2017/9/1.
//  Copyright © 2017年 GouLiao11. All rights reserved.
//

#import "XZUserKVStoreManage.h"
#import "YTKKeyValueStore.h"

#define MsgDBVersionTable @"MsgDBVersion"
#define UserLogLevelTable @"UserLogLevel"
#define TaskListTable     @"TaskList"
#define DownloadListTable @"DownloadListTable"

@interface XZUserKVStoreManage ()

@property (nonatomic, strong) YTKKeyValueStore *store;

@end

static XZUserKVStoreManage *instance = nil;
@implementation XZUserKVStoreManage

+ (instancetype)shareInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[XZUserKVStoreManage alloc] init];
    });
    return instance;
}

/**
 *	@brief	修改数据库名
 *
 */
- (void)reviseDBName {
    
    NSString *user_dbName = [self getDBName];// 获取用户数据库名称
    NSString *oldDBPath = [NSString stringWithFormat:@"%@/%@_DBVersion.sqlite",DOCUMENTS_PATH,user_dbName];
    NSString *newDBPath = [NSString stringWithFormat:@"%@/%@_userKVStore.sqlite",DOCUMENTS_PATH,user_dbName];
    if ([[NSFileManager defaultManager] fileExistsAtPath:oldDBPath]) {
        
        NSError *err = nil;
        [[NSFileManager defaultManager] moveItemAtPath:oldDBPath toPath:newDBPath error:&err];
        
        if (err) {
            
            DDLogError(@"userKVStore数据库名字替换失败");
        }
        
    }
    
}

/**
 *	@brief	存字典到数据库
 *
 *	@param 	saveDic 	字典
 *	@param 	tableName 	表名
 *	@param 	key 	    key
 */
- (void)saveObject:(id<NSCoding>)object TableName:(NSString *)tableName key:(NSString *)key {
    
    BOOL isSave = [self.store putObject:object
                                 withId:key
                              intoTable:tableName];
    if (isSave) {
        
        DDLogInfo(@"存入%@表成功",tableName);
    } else {
        
        DDLogError(@"存入%@表失败",tableName);
    }
}

/**
 *	@brief	获取数据库中对象
 *
 *	@param 	tableName 	表名
 *	@param 	key 	    key
 */
- (id)getObjectWithTableName:(NSString *)tableName key:(NSString *)key {
    
    return [self.store getObjectById:key
                           fromTable:tableName];
}

/**
 *	@brief	存Number到数据库
 *
 *	@param 	saveNumber 	Number
 *	@param 	tableName 	表名
 *	@param 	key 	    key
 */
- (void)saveNumberWithNumber:(NSNumber *)saveNumber TableName:(NSString *)tableName key:(NSString *)key {
    
    [self.store putNumber:saveNumber
                   withId:key
                intoTable:tableName];
    
}

/**
 *	@brief	获取数据库中Number
 *
 *	@param 	tableName 	表名
 *	@param 	key 	    key
 */
- (NSNumber *)getNumberWithTableName:(NSString *)tableName key:(NSString *)key {
    
    return [self.store getNumberById:key
                           fromTable:tableName];
}

/**
 *	@brief	清除数据库
 *
 *	@param 	tableName 	表名
 */
- (void)cleanDBWithTableName:(NSString *)tableName {
    
    [self.store clearTable:tableName];
}

/**
 *	@brief	删除对象
 *
 *	@param 	tableName 	表名
 */
- (void)deleteObjectWithTableName:(NSString *)tableName key:(NSString *)key {
    
    [self.store deleteObjectById:key fromTable:tableName];
}


/**
 *  获取用户名
 *
 */
- (NSString *)getDBName
{
    //数据库名应该是用户的ID再md5后的字符串
    NSString *userDBName = @"12345";
    
    return userDBName;
}

#pragma mark - getter

- (YTKKeyValueStore *)store {
    if (!_store) {
        
        NSString *user_dbName = [self getDBName];// 获取用户数据库名称
        // 初始化store
        _store = [[YTKKeyValueStore alloc] initDBWithName:[NSString stringWithFormat:@"%@_userKVStore.sqlite",user_dbName]];
        [_store createTableWithName:MsgDBVersionTable];
        [_store createTableWithName:UserLogLevelTable];
        [_store createTableWithName:TaskListTable];
        [_store createTableWithName:DownloadListTable];
    }
    return _store;
}

@end
