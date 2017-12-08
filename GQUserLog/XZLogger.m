//
//  XZLogger.m
//  Xiezhu
//
//  Created by qing on 2017/8/25.
//  Copyright © 2017年 GouLiao11. All rights reserved.
//

#import "XZLogger.h"
#import "DDLog.h"
#import "XZLogFormatter.h"

@interface XZLogger ()

/**<#注释#> */
@property (nonatomic, strong) NSMutableArray *logMessagesArray;
/**<#注释#> */
@property (nonatomic, strong) NSString *fileName;

@end

@implementation XZLogger

- (instancetype)init {
    self = [super init];
    if (self) {
        self.deleteInterval = 0;
        self.maxAge = 0;
        self.deleteOnEverySave = NO;
        self.saveInterval = 60;
        self.saveThreshold = 500;//当未保存的log达到500条时，会调用db_save方法保存
        
        //注册app切换到后台通知，保存日志到沙盒
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(saveLog)
                                                     name:@"UIApplicationWillResignActiveNotification"
                                                   object:nil];
    }
    return self;
}

- (void)saveLog {
    dispatch_async(_loggerQueue, ^{
        [self db_save];
    });
}

/**
 *  每次打 log 时，db_log会被调用
 *
 */
- (BOOL)db_log:(DDLogMessage *)logMessage
{
    if (!_logFormatter) {
        //没有指定 formatter
        return NO;
    }
    
    if (!_logMessagesArray)
        _logMessagesArray = [NSMutableArray arrayWithCapacity:500]; // saveThreshold只设置了500条
    
    
    //利用 formatter 得到消息字符串，添加到缓存，当调用db_save时，写入沙盒
    [_logMessagesArray addObject:[_logFormatter formatLogMessage:logMessage]];
    return YES;
}


/**
 *  每隔1分钟或者未写入文件的log数达到 500 时，db_save 就会被调用
 *
 */
- (void)db_save{
    //判断是否在 logger 自己的GCD队列中
    if (![self isOnInternalLoggerQueue])
        NSAssert(NO, @"db_saveAndDelete should only be executed on the internalLoggerQueue thread, if you're seeing this, your doing it wrong.");
    
    //如果缓存内没数据，啥也不做
    if ([_logMessagesArray count] == 0) {
        return;
    }
    //获取缓存中所有数据，之后将缓存清空
    NSArray *oldLogMessagesArray = [_logMessagesArray copy];
    _logMessagesArray = [NSMutableArray arrayWithCapacity:0];
    
    //用换行符，把所有的数据拼成一个大字符串
    NSString *logMessagesString = [oldLogMessagesArray componentsJoinedByString:@"\n"];
    
    
    //判断有没有文件夹，如果没有，就创建
    NSString *createPath = [NSString stringWithFormat:@"%@/Logs/%@",DOCUMENTS_PATH,oyToStr(USERID)];
    NSString *txtPath = [NSString stringWithFormat:@"%@/%@",createPath,self.fileName];
    if ([[NSFileManager defaultManager] fileExistsAtPath:createPath]) {
       
        if (![[NSFileManager defaultManager] fileExistsAtPath:txtPath]) {
            
            [[NSFileManager defaultManager] createFileAtPath:txtPath contents:nil attributes:nil];
        }
        
    } else {
        
        [[NSFileManager defaultManager] createDirectoryAtPath:createPath withIntermediateDirectories:YES attributes:nil error:nil];
        
        [[NSFileManager defaultManager] createFileAtPath:txtPath contents:nil attributes:nil];
    }
    
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForUpdatingAtPath:txtPath];
    
    [fileHandle seekToEndOfFile];  //将节点跳到文件的末尾
    NSData* stringData  = [[NSString stringWithFormat:@"\n%@",logMessagesString] dataUsingEncoding:NSUTF8StringEncoding];
    [fileHandle writeData:stringData]; //追加写入数据
    
    [fileHandle closeFile];
    
    //跳过iCloud上传
    [self addSkipBackupAttributeToItemAtPath:txtPath];


}

- (BOOL)addSkipBackupAttributeToItemAtPath:(NSString *) filePathString
{
    NSURL* URL= [NSURL fileURLWithPath: filePathString];
    assert([[NSFileManager defaultManager] fileExistsAtPath: [URL path]]);
    
    NSError *error = nil;
    BOOL success = [URL setResourceValue: [NSNumber numberWithBool: YES]
                                  forKey: NSURLIsExcludedFromBackupKey error: &error];
    if(!success){
        NSString *err = [NSString stringWithFormat:@"Error excluding %@ from backup %@", [URL lastPathComponent], error];
    }
    return success;
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

- (NSString *)fileName {
    if (!_fileName) {
        _fileName = [NSString stringWithFormat:@"GQ_Log_%@.txt",[self timestampToNSString:[self getCurrentDate] formatter:@"yyyy-MM-dd"]];
    }
    return _fileName;
}

@end
