//
//  NSObject+XY.h
//  JoinShow
//
//  Created by Heaven on 13-7-31.
//  Copyright (c) 2013年 Heaven. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (XY)

#pragma mark - perform

#pragma mark - property
// 属性列表
@property (nonatomic, readonly, strong) NSArray                *attributeList;

#pragma mark - Conversion
- (NSInteger)asInteger;
- (float)asFloat;
- (BOOL)asBool;

- (NSNumber *)asNSNumber;
- (NSString *)asNSString;
- (NSDate *)asNSDate;
- (NSData *)asNSData;	// TODO
- (NSArray *)asNSArray;
//- (NSArray *)asNSArrayWithClass:(Class)clazz;
- (NSMutableArray *)asNSMutableArray;
//-(NSMutableArray *) asNSMutableArrayWithClass:(Class)clazz;
- (NSDictionary *)asNSDictionary;
- (NSMutableDictionary *)asNSMutableDictionary;

#pragma mark- copy
// 基于NSKeyArchive.如果 self导入XYAutoCoding.h,可用与自定义对象
- (id)deepCopy1;

#pragma mark- associated
- (id)getAssociatedObjectForKey:(const char *)key;
- (id)copyAssociatedObject:(id)obj forKey:(const char *)key;
- (id)retainAssociatedObject:(id)obj forKey:(const char *)key;
- (id)assignAssociatedObject:(id)obj forKey:(const char *)key;
- (void)removeAssociatedObjectForKey:(const char *)key;
- (void)removeAllAssociatedObjects;

@end

#pragma mark - FlyweightTransmit
@protocol FlyweightTransmit

@property (nonatomic, strong) id                tempObject;

// send object
// handle block with default identifier is @"sendObject".
- (void)receiveObject:(void(^)(id object))aBlock;
- (void)sendObject:(id)anObject;

//tag can't be nil
- (void)receiveObject:(void(^)(id object))aBlock withIdentifier:(NSString *)identifier;
- (void)sendObject:(id)anObject withIdentifier:(NSString *)identifier;

// handle block with default identifier is @"EventBlock".
- (void)handlerDefaultEventWithBlock:(id)aBlock;
- (id)blockForDefaultEvent;

// 设置一个block作为回调
- (void)handlerEventWithBlock:(id)aBlock withIdentifier:(NSString *)identifier;
- (id)blockForEventWithIdentifier:(NSString *)identifier;

@end





