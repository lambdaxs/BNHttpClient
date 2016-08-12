//
//  HttpClient.h
//  NetworkManager
//
//  Created by xiaos on 16/4/26.
//  Copyright © 2016年 wzx. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFHTTPSessionManager.h"


#define XSHttpClient [HttpClient manager]

static NSString *DebugHost;
static NSString *ServerHost;

@interface HttpClient : AFHTTPSessionManager

//设置正式服务器地址 和 测试服务器地址 建议在appDelegate中设置
+ (void)setServerHost:(NSString *)serverHost debugHost:(NSString *)debugHost;

//请求类型
typedef NS_ENUM(NSInteger, RequestType){
    GET,
    POST,
    UPLOAD
};

//请求解析类型
typedef NS_ENUM(NSInteger, RequestSerializer){
    requestHttp,
    requestJson
};

//响应解析类型
typedef NS_ENUM(NSInteger, ResponseSerializer){
    responseHttp,
    responseJson
};


+ (HttpClient *)manager;

- (HttpClient *)make;

- (HttpClient *)and;

//设置请求方式 GET POST UPLOAD...
//- (HttpClient *(^)(RequestType type))setRequestType;

//设置请求url
- (HttpClient *(^)(NSString *url))url;

//设置请求参数
- (HttpClient *(^)(id params))params;

//模拟form上传时设置上传数据 传入的字典中有三个键data name fileName fileType
- (HttpClient *(^)(NSDictionary *))setFile;

//设置请求头
- (HttpClient *(^)(NSDictionary *headerDict))setHttpHeader;

//设置请求解析方式
- (HttpClient *(^)(RequestSerializer type))setRequestSerializer;

//设置响应解析方式
- (HttpClient *(^)(ResponseSerializer type))setResponseSerializer;

//设置响应接收格式
- (HttpClient *(^)(NSString *format))appendAcceptFormat;

//设置是否用测试服务器
- (HttpClient *(^)(BOOL isDebug))DeBug;

//开始请求
- (void)data:(void (^)(id))data
     failure:(void (^)())failure;

- (void)data:(void (^)(id))data
     failure:(void (^)())failure
      always:(void(^)())always;

@end

HttpClient * XSHttp(RequestType type);

