//
//  BNHttpQueue.h
//  BNHttpClientProject
//
//  Created by xiaos on 16/8/17.
//  Copyright © 2016年 com.xsdota. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BNHttpQueue : NSObject
@property (nonatomic,copy) NSString *requestType;   ///< 请求方式 @"GET" @"POST"
@property (nonatomic,copy) NSString *url;           ///< 请求路径
@property (nonatomic,strong) id param;              ///< 请求参数
@property (nonatomic,copy) NSString *resultId;      ///< 回调字典中的key

- (instancetype)initWithRequestType:(NSString *)type
                                url:(NSString *)url
                              param:(id)param
                           resultId:(NSString *)resultId;
@end


@interface BNHttpTarget : NSObject
- (instancetype)initWithQueue:(NSArray<BNHttpQueue *> *)qs
                      success:(void(^)(NSDictionary *all))success
                         some:(void(^)(NSDictionary *some,NSArray<NSString *> *failureKeys))some;

- (BOOL)isAllSuccess;
@end