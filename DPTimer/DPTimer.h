//
//  DPTimer.h
//
//  Created by dp on 2021/8/24.
//  Copyright © 2021 dp. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef void(^DPTimerChangeBlock)(double time);
typedef void(^DPTimerFinishBlock)(NSString *identifier);
NS_ASSUME_NONNULL_BEGIN

@interface DPTimer : NSObject
/**
 *task 定时器回调
 *start几秒以后开始
 *interval每隔几秒执行一次
 *endInterval多少秒以后结束  repeats设置为YES时候生效
 *repeats 是否重复
 *async是否异步执行
 */
+ (NSString *)execTask:(DPTimerChangeBlock)task
           finish:(DPTimerFinishBlock)finishBlock
           start:(NSTimeInterval)start
        interval:(NSTimeInterval)interval
        endInterval:(NSTimeInterval)endInterval
         repeats:(BOOL)repeats
           async:(BOOL)async;
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
           async:(BOOL)async;
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
           async:(BOOL)async;

+ (void)cancelTask:(NSString *)identifier;
@end

NS_ASSUME_NONNULL_END
