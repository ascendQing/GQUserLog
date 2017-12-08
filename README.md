# GQUserLog
> ##前言
> 对于一个已经上线的产品，如果项目没有自己的Log系统，产品在线上出现问题，那就只能抓瞎了，所以项目中有一套自己成熟的Log系统是至关重要的。本文主要利用CocoaLumberjack来教大家如何去搭建自己的Log系统。当然，每个项目有自己不同的业务逻辑，你们也可以根据自己项目的业务逻辑来修改就好。

CocoaLumberjack是一个可以在iOS和Mac开发中使用的日志库，使用很简单，但很功能很强大。在这里就不多作介绍了，大家可以去官网上看 -->[CocoaLumberjack](http://www.jianshu.com)

----------------------------

好了，现在该说说如何去构建自己的Log系统了。


![Log系统原理图](http://upload-images.jianshu.io/upload_images/2311016-c5bb48a413840b99.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

####先介绍一下主要构成Log系统的四大类：
##### 1、`XZLogFormatter` 

 该类主要是根据我们自己设定的格式输出我们需要保存的log。
-  主要实现`DDLogFormatter`协议
- .m文件中重写`- (NSString *)formatLogMessage:(DDLogMessage *)logMessage`方法。这个方法返回值是 NSString，就是最终 log 的消息体字符串。参数 logMessage 是由 logger 发的一个 DDLogMessage 对象。下面贴出方法内部实现
```
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
```
##### 2、`XZLogger` 

-  自定义 logger，继承`DDAbstractDatabaseLogger`。在初始化方法中，先设定一些基本参数，并且添加一个UIApplicationWillResignActiveNotification的观察者，这主要作用是app切换到后台会有通知，保存日志到沙盒。
```
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
```
-  重写`- (BOOL)db_log:(DDLogMessage *)logMessage`方法，每次打 log 时，db_log就会被调用。该方法主要内容是将 log 发给 formatter，将返回的 log 消息体字符串保存在缓存中。 db_log 的返回值告诉 DDLog 该条 log 是否成功保存进缓存。
```
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
```
-  每隔1分钟或者未写入文件的log数达到 500 时，db_save 就会自动被调用，这个时候我们就可以把存在缓存中的Log全部写入沙盒文件了
```
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
```
##### 3、`XZUserLogManager` 
该类有3个作用
-  删除过期Log，目前我定的只保留3天的Log，多余的全部清除，时间可以随意改，无所谓的。
```
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
```
-  动态修改Log等级和上传Log到服务器，这里需要说明一点，我们项目是有即时通讯的，所有需要修改Log等级，只需要给用户推一条消息，然后用户收到消息后，就可以去修改Log等级了。后面说到`XZDynamicLogLevel`类的时候，会详细说明。所以上传Log也是会给用户推消息，用户就后台自动上传Log到服务器了。所以你们看见的`XZMessageModel`对象就是我们项目中的消息体对象，这一块得根据你们具体的业务来设计。
```
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
```
##### 4、`XZDynamicLogLevel` 
-  该类就是动态调整log等级，先遵守`DDRegisteredDynamicLogging`协议
- 重写`+ (void)ddSetLogLevel:(DDLogLevel)level`方法。收到动态修改Log等级的消息后，就取出消息中给的Log等级，然后存数据库
```
+ (void)ddSetLogLevel:(DDLogLevel)level {
    
    [[XZUserKVStoreManage shareInstance] saveNumberWithNumber:@(level)
                                                    TableName:XZ_USER_LOG_LEVEL_DB_NAME
                                                          key:XZ_USER_LOG_LEVEL_DB_KEY];
}
```
- 重写`+ (DDLogLevel)ddLogLevel`方法，每次打印log会获取log等级，也就是会走`+ (DDLogLevel)ddLogLevel`方法，在`ddLogLevel`方法中，我们每次都会去获取我们保存的Log等级
```
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
```
##### 5、`AppDelegate` 

-  AppDelegate中也需要做一些设置
```
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    // 启动日志
    //删除过期日志
    [[XZUserLogManager shareInstance] deleteOutOfDateLog];
    // 添加DDASLLogger，你的日志语句将被发送到Xcode控制台
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    
    // 添加DDTTYLogger，你的日志语句将被发送到Console.app
    [DDLog addLogger:[DDASLLogger sharedInstance]];
    
    XZLogger *logger = [[XZLogger alloc] init];
    [logger setLogFormatter:[[XZLogFormatter alloc] init]];
    [DDLog addLogger:logger];
    
    DDLogInfo(@"%@",DOCUMENTS_PATH);
    DDLogInfo(@"打印info");
    DDLogWarn(@"打印Warn");
    DDLogError(@"打印Error");
    
    return YES;
}
```

这就是保存到沙盒的Log文件
![582481A5-EA34-4A1A-85E0-63F5FB09E3C7.png](http://upload-images.jianshu.io/upload_images/2311016-888eea44a4f91898.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
