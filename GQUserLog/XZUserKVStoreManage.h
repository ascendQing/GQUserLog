//
//  XZUserKVStoreManage.h
//  Xiezhu
//
//  Created by qing on 2017/9/1.
//  Copyright © 2017年 GouLiao11. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XZUserKVStoreManage : NSObject

+ (instancetype)shareInstance;

/**
 *	@brief	修改数据库名
 *
 */
- (void)reviseDBName;

/**
 *	@brief	存字典到数据库
 *
 *	@param 	saveDic 	字典
 *	@param 	tableName 	表名
 *	@param 	key 	    key
 */
- (void)saveObject:(id)object
         TableName:(NSString *)tableName
               key:(NSString *)key;

/**
 *	@brief	获取数据库中对象
 *
 *	@param 	tableName 	表名
 *	@param 	key 	    key
 */
- (id)getObjectWithTableName:(NSString *)tableName
                         key:(NSString *)key;

/**
 *	@brief	存Number到数据库
 *
 *	@param 	saveNumber 	Number
 *	@param 	tableName 	表名
 *	@param 	key 	    key
 */
- (void)saveNumberWithNumber:(NSNumber *)saveNumber
                   TableName:(NSString *)tableName
                         key:(NSString *)key;

/**
 *	@brief	获取数据库中Number
 *
 *	@param 	tableName 	表名
 *	@param 	key 	    key
 */
- (NSNumber *)getNumberWithTableName:(NSString *)tableName
                                 key:(NSString *)key;

/**
 *	@brief	清除数据库
 *
 *	@param 	tableName 	表名
 */
- (void)cleanDBWithTableName:(NSString *)tableName;

/**
 *	@brief	删除对象
 *
 *	@param 	tableName 	表名
 */
- (void)deleteObjectWithTableName:(NSString *)tableName
                              key:(NSString *)key;


@end
