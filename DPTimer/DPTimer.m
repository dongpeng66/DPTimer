//
//  DPTimer.m
//
//  Created by dp on 2021/8/24.
//  Copyright © 2021 dp. All rights reserved.
//

#import "DPTimer.h"

#define DPTimerPath(name)  [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:[NSString stringWithFormat:@"DPTTimer_%@_Timer",name]]

@interface DPTimerModel : NSObject
/** 原始开始时间秒 */
@property (nonatomic, assign) NSTimeInterval oriTime;
/** 进度单位 */
@property (nonatomic, assign) NSTimeInterval unit;

/** 是否本地持久化保存定时数据 */
@property (nonatomic,assign) BOOL isDisk;
/** 标识 */
@property (nonatomic, copy) NSString *identifier;

@end
@implementation DPTimerModel

+ (instancetype)timeInterval:(NSInteger)timeInterval {
    DPTimerModel *object = [DPTimerModel new];
    object.unit = timeInterval;
    return object;
}
- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeDouble:self.oriTime forKey:@"oriTime"];
    [aCoder encodeDouble:self.unit forKey:@"unit"];
    [aCoder encodeBool:self.isDisk forKey:@"isDisk"];
    [aCoder encodeObject:self.identifier forKey:@"identifier"];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        self.oriTime = [aDecoder decodeDoubleForKey:@"oriTime"];
        self.unit = [aDecoder decodeDoubleForKey:@"unit"];
        self.isDisk = [aDecoder decodeBoolForKey:@"isDisk"];
        self.identifier = [aDecoder decodeObjectForKey:@"identifier"];
    }
    return self;
}

@end


@implementation DPTimer

static NSMutableDictionary *timers_;
static NSMutableDictionary *allTimers_;
static NSMutableDictionary *timerMdic_;
dispatch_semaphore_t semaphore_;
//static DPTimer *_instance;
//DPTimer *DPTimerM() {
//    return [DPTimer sharedInstance];
//}
+ (void)initialize
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        timers_ = [NSMutableDictionary dictionary];
        allTimers_ = [NSMutableDictionary dictionary];
        timerMdic_=[NSMutableDictionary dictionary];
        semaphore_ = dispatch_semaphore_create(1);
    });
}
//+ (instancetype)sharedInstance {
//    if (!_instance) {
//        static dispatch_once_t onceToken;
//        dispatch_once(&onceToken, ^{
//            _instance = [[self alloc] init];
//        });
//    }
//    return _instance;
//}
//
//
//+ (id)allocWithZone:(struct _NSZone *)zone {
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        _instance = [super allocWithZone:zone];
//    });
//    return _instance;
//}


+ (NSString *)execTask:(DPTimerChangeBlock)task
           finish:(DPTimerFinishBlock)finishBlock
           start:(NSTimeInterval)start
        interval:(NSTimeInterval)interval
        endInterval:(NSTimeInterval)endInterval
         repeats:(BOOL)repeats
           async:(BOOL)async
{
    // 定时器的唯一标识
    NSString *identifier = [NSString stringWithFormat:@"%zd", timers_.count];
    
    
    return [self execTask:task finish:finishBlock start:start interval:interval endInterval:endInterval identifier:identifier repeats:repeats async:async];
}
/**
 *task 定时器回调
 *start几秒以后开始
 *interval每隔几秒执行一次
 *endInterval多少秒以后结束  repeats设置为YES时候生效
 *identifier 定时器唯一标识
 *repeats 是否重复
 *async是否异步执行
 */
+ (NSString *)execTask:(DPTimerChangeBlock)task
           finish:(DPTimerFinishBlock)finishBlock
           start:(NSTimeInterval)start
        interval:(NSTimeInterval)interval
        endInterval:(NSTimeInterval)endInterval
        identifier:(NSString *)identifier
         repeats:(BOOL)repeats
                 async:(BOOL)async{
    if (!task || start < 0 || (interval <= 0 && repeats)) return nil;
    
    // 队列
    dispatch_queue_t queue = async ? dispatch_get_global_queue(0, 0) : dispatch_get_main_queue();
    
    // 创建定时器
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    
    // 设置时间
    dispatch_source_set_timer(timer,
                              dispatch_time(DISPATCH_TIME_NOW, start * NSEC_PER_SEC),
                              interval * NSEC_PER_SEC, 0);
    
    
    dispatch_semaphore_wait(semaphore_, DISPATCH_TIME_FOREVER);
    // 定时器的唯一标识
    // 存放到字典中
    timers_[identifier] = timer;
    allTimers_[identifier]=[NSString stringWithFormat:@"%f",endInterval];
    dispatch_semaphore_signal(semaphore_);
    
    // 设置回调
    dispatch_source_set_event_handler(timer, ^{
        
        if (!repeats) { // 不重复的任务
            [self cancelTask:identifier];
            finishBlock(identifier);
        }else{
            NSString *endString=allTimers_[identifier];
            double time=[endString doubleValue]-interval;
            if (time<0) {
                [self cancelTask:identifier];
                finishBlock(identifier);
            }else{
                task(time);
                dispatch_semaphore_wait(semaphore_, DISPATCH_TIME_FOREVER);
                // 存放到字典中
                allTimers_[identifier]=[NSString stringWithFormat:@"%f",time];
                dispatch_semaphore_signal(semaphore_);
            }
        }
    });
    
    // 启动定时器
    dispatch_resume(timer);
    
    return [self execTask:task finish:finishBlock start:start interval:interval endInterval:endInterval identifier:identifier forIsDisk:NO repeats:repeats async:async];
}
/**
 *task 定时器回调
 *start几秒以后开始
 *interval每隔几秒执行一次
 *endInterval多少秒以后结束  repeats设置为YES时候生效
 *identifier 定时器唯一标识
 *isDisk 是否本地存储
 *repeats 是否重复
 *async是否异步执行
 */
+ (NSString *)execTask:(DPTimerChangeBlock)task
           finish:(DPTimerFinishBlock)finishBlock
           start:(NSTimeInterval)start
        interval:(NSTimeInterval)interval
        endInterval:(NSTimeInterval)endInterval
        identifier:(NSString *)identifier
        forIsDisk:(BOOL)isDisk
         repeats:(BOOL)repeats
                 async:(BOOL)async{
    if (!task || start < 0 || (interval <= 0 && repeats)) return nil;
    NSString *identifierString=identifier;
    if (identifierString.length<0) {
        DPTimerModel *model = [DPTimerModel timeInterval:endInterval];
        model.isDisk = isDisk;
        model.identifier = [NSString stringWithFormat:@"%p",model];
        identifierString = [NSString stringWithFormat:@"%p",model];
        model.unit = endInterval;
        if (isDisk) {
            DPTimerModel *oldModel=[self loadTimerForIdentifier:identifierString];
            if (oldModel) {
                //存储的未执行完的定时器任务
                [timerMdic_ setObject:oldModel forKey:oldModel.identifier];
                dispatch_semaphore_wait(semaphore_, DISPATCH_TIME_FOREVER);
                // 定时器的唯一标识
                allTimers_[identifierString]=[NSString stringWithFormat:@"%f",oldModel.unit];
                dispatch_semaphore_signal(semaphore_);
            }else{
                //新建定时器任务
                [timerMdic_ setObject:model forKey:model.identifier];
                dispatch_semaphore_wait(semaphore_, DISPATCH_TIME_FOREVER);
                // 定时器的唯一标识
                allTimers_[identifierString]=[NSString stringWithFormat:@"%f",model.unit];
                dispatch_semaphore_signal(semaphore_);
            }
        }
        
    }else{
        //唯一标识符可用
        DPTimerModel *model = [DPTimerModel timeInterval:endInterval];
        model.isDisk = isDisk;
        model.identifier = identifierString;
        model.unit = endInterval;
        if (isDisk) {
            DPTimerModel *oldModel=[self loadTimerForIdentifier:identifierString];
            if (oldModel) {
                //存储的未执行完的定时器任务
                [timerMdic_ setObject:oldModel forKey:oldModel.identifier];
                dispatch_semaphore_wait(semaphore_, DISPATCH_TIME_FOREVER);
                // 定时器的唯一标识
                allTimers_[identifierString]=[NSString stringWithFormat:@"%f",oldModel.unit];
                dispatch_semaphore_signal(semaphore_);
            }else{
                //新建定时器任务
                [timerMdic_ setObject:model forKey:model.identifier];
                dispatch_semaphore_wait(semaphore_, DISPATCH_TIME_FOREVER);
                // 定时器的唯一标识
                allTimers_[identifierString]=[NSString stringWithFormat:@"%f",model.unit];
                dispatch_semaphore_signal(semaphore_);
            }
        }
    }
    
    
    // 队列
    dispatch_queue_t queue = async ? dispatch_get_global_queue(0, 0) : dispatch_get_main_queue();
    
    // 创建定时器
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    
    // 设置时间
    dispatch_source_set_timer(timer,
                              dispatch_time(DISPATCH_TIME_NOW, start * NSEC_PER_SEC),
                              interval * NSEC_PER_SEC, 0);
    
    
    dispatch_semaphore_wait(semaphore_, DISPATCH_TIME_FOREVER);
    // 定时器的唯一标识
    // 存放到字典中
    timers_[identifierString] = timer;
    dispatch_semaphore_signal(semaphore_);
    
    // 设置回调
    dispatch_source_set_event_handler(timer, ^{
        
        if (!repeats) { // 不重复的任务
            [self cancelTask:identifierString];
            finishBlock(identifierString);
        }else{
            NSString *endString=allTimers_[identifierString];
            double time=[endString doubleValue]-interval;
            if (time<0) {
                [self cancelTask:identifierString];
                finishBlock(identifierString);
            }else{
                task(time);
                dispatch_semaphore_wait(semaphore_, DISPATCH_TIME_FOREVER);
                // 存放到字典中
                allTimers_[identifierString]=[NSString stringWithFormat:@"%f",time];
                DPTimerModel *currentModel=[timerMdic_ objectForKey:identifierString];
                currentModel.unit=time;
                [self savaForTimerModel:currentModel];
                dispatch_semaphore_signal(semaphore_);
            }
        }
    });
    
    // 启动定时器
    dispatch_resume(timer);
    
    return identifier;
}
+ (void)cancelTask:(NSString *)identifier
{
    if (identifier.length == 0) return;
    
    dispatch_semaphore_wait(semaphore_, DISPATCH_TIME_FOREVER);
    
    dispatch_source_t timer = timers_[identifier];
    if (timer) {
        dispatch_source_cancel(timer);
        [timers_ removeObjectForKey:identifier];
        [allTimers_ removeObjectForKey:identifier];
        [timerMdic_ removeObjectForKey:identifier];
        [self deleteForIdentifier:identifier];
    }

    dispatch_semaphore_signal(semaphore_);
}

#pragma mark - ***** other *****

+ (BOOL)timerIsExistInDiskForIdentifier:(NSString *)identifier {
    NSString *filePath = DPTimerPath(identifier);
    BOOL isExist = [[NSFileManager defaultManager] fileExistsAtPath:filePath];
    return isExist;
}

+ (BOOL)savaForTimerModel:(DPTimerModel *)model {
    NSString *filePath = DPTimerPath(model.identifier);
    return [NSKeyedArchiver archiveRootObject:model toFile:filePath];
}

+ (DPTimerModel *)loadTimerForIdentifier:(NSString *)identifier{
    NSString *filePath = DPTimerPath(identifier);
    return [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
}

+ (BOOL)deleteForIdentifier:(NSString *)identifier {
    NSString *filePath = DPTimerPath(identifier);
    NSFileManager* fileManager = [NSFileManager defaultManager];
    BOOL isExist = [fileManager fileExistsAtPath:filePath];
    if (isExist) {
        return [fileManager removeItemAtPath:filePath error:nil];
    }
    return NO;
}

+ (DPTimerModel *)getTimerModelForIdentifier:(NSString *)identifier {
    if (identifier.length<=0) {
        return nil;
    }
    if ([self timerIsExistInDiskForIdentifier:identifier]) {
        DPTimerModel *model = [DPTimer loadTimerForIdentifier:identifier];
        return model;
    }else{
        return nil;
    }
    
    
}
@end
