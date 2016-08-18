//
//  BNHttpClient.h
//  NetworkManager
//
//  Created by xiaos on 16/4/26.
//  Copyright © 2016年 wzx. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFHTTPSessionManager.h"

@interface BNHttpClient : AFHTTPSessionManager

//设置正式服务器地址 和 测试服务器地址 建议在appDelegate中设置
+ (void)setServerHost:(NSString *)serverHost debugHost:(NSString *)debugHost;

//设置请求url
- (BNHttpClient *(^)(NSString *))url;

//设置请求参数
- (BNHttpClient *(^)(id))params;

//设置请求头
- (BNHttpClient *(^)(NSString *key,id value))addHttpHeader;

//设置请求解析方式
- (BNHttpClient *(^)(NSString *))setRequestSerializer;

//设置响应解析方式
- (BNHttpClient *(^)(NSString *))setResponseSerializer;

//设置响应接收格式
- (BNHttpClient *(^)(NSString *))addAcceptFormat;

//设置是否用测试服务器
- (BNHttpClient *(^)(BOOL isDebug))DeBug;

//模拟form上传时设置上传数据 传入的字典中有四个键值对
//文件二进制数据：data 参数名称：name 文件名称：fileName 文件类型：fileType
- (BNHttpClient *(^)(NSDictionary *))setFile;

//开始请求
- (void)jsonData:(void(^)(id data))jsonData;

- (void)data:(void (^)(id data))data
     failure:(void (^)())failure;

- (void)data:(void (^)(id data))data
     failure:(void (^)())failure
      always:(void(^)())always;

@end

BNHttpClient * BNHttp(NSString *type);

//快捷请求json数据
void BNGetJsonData(NSString *url,id param,void(^callBack)(id jsonData));

