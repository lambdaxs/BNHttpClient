//
//  BNHttpClient.m
//  NetworkManager
//
//  Created by xiaos on 16/4/26.
//  Copyright © 2016年 wzx. All rights reserved.
//

#import "BNHttpClient.h"

static NSString *DebugHost;
static NSString *ServerHost;

//请求类型
typedef NS_ENUM(NSInteger, BNRequestType){
    GET =       0 << 1,
    POST =      1 << 2,
    UPLOAD =    2 << 3
};

//请求解析类型
typedef NS_ENUM(NSInteger, BNRequestSerializer){
    requestHttp = 0 << 1,
    requestJson = 1 << 2
};

//响应解析类型
typedef NS_ENUM(NSInteger, BNResponseSerializer){
    responseHttp = 0 << 1,
    responseJson = 1 << 2
};

@interface BNHttpClient ()
@property (nonatomic,copy)NSString *mUrl;
@property (nonatomic,assign)BNRequestType mRequestType;
@property (nonatomic,assign)BNRequestSerializer mRequestSerializer;
@property (nonatomic,assign)BNResponseSerializer mResponseSerializer;
@property (nonatomic,copy)id mParameters;
@property (nonatomic,strong) NSMutableDictionary *mHeader;
@property (nonatomic,copy) NSDictionary * mFileDict;
@property (nonatomic,copy) NSSet *acceptFormat;
@property (nonatomic,assign)BOOL isDebug;
@end

@implementation BNHttpClient

+ (void)setServerHost:(NSString *)serverHost debugHost:(NSString *)debugHost{
    ServerHost = serverHost;
    DebugHost = debugHost;
}

+ (BNHttpClient *)manager {
    static BNHttpClient *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[BNHttpClient alloc] init];
        [manager update];
    });
    return manager;
}


- (BNHttpClient *(^)(NSString *))url {
    return ^BNHttpClient *(NSString *url){
        self.mUrl = url;
        return self;
    };
}

- (BNHttpClient *(^)(id))params{
    return ^BNHttpClient *(id p){
        self.mParameters = p;
        return self;
    };
}

- (BNHttpClient *(^)(NSString *key,id value))addHttpHeader {
    return ^BNHttpClient *(NSString *key,id value){
        if (!self.mHeader) {
            self.mHeader = [NSMutableDictionary dictionary];
        }
        self.mHeader[key] = value;
        return self;
    };
}

- (BNHttpClient *(^)(NSString *))setRequestType {
    return ^BNHttpClient *(NSString *type){
        NSString *typeStr = [type uppercaseString];
        BNRequestType requestType;
        if ([typeStr isEqualToString:@"GET"]) {
            requestType = GET;
        }else if ([typeStr isEqualToString:@"POST"]){
            requestType = POST;
        }else if ([typeStr isEqualToString:@"UPLOAD"]){
            requestType = UPLOAD;
        }else {
            requestType = GET;
        }
        self.mRequestType = requestType;
        return self;
    };
}

- (BNHttpClient *(^)(NSString *))setRequestSerializer{
    return ^BNHttpClient *(NSString *type){
        NSString *typeStr = [type uppercaseString];
        BNRequestSerializer requestSer;
        if ([typeStr isEqualToString:@"HTTP"]) {
            requestSer = requestHttp;
        }else if ([typeStr isEqualToString:@"JSON"]){
            requestSer = requestJson;
        }else {
            requestSer = requestHttp;
        }
        self.mRequestSerializer = requestSer;
        return self;
    };
}

- (BNHttpClient *(^)(NSString *))setResponseSerializer{
    return ^BNHttpClient *(NSString *type){
        NSString *typeStr = [type uppercaseString];
        BNResponseSerializer responseSer;
        if ([typeStr isEqualToString:@"HTTP"]) {
            responseSer = responseHttp;
        }else if ([typeStr isEqualToString:@"JSON"]){
            responseSer = responseJson;
        }else {
            responseSer = responseHttp;
        }
        self.mResponseSerializer = responseSer;
        return self;
    };
}


- (BNHttpClient *(^)(NSString *))addAcceptFormat {
    return ^BNHttpClient *(NSString *format){
        NSMutableSet *set = [NSMutableSet setWithSet:self.acceptFormat];
        [set addObject:format];
        self.acceptFormat = set;
        return self;
    };
}

- (BNHttpClient *(^)(NSDictionary *))setFile {
    NSAssert(self.mRequestType == UPLOAD, @"GET POST 请求不支持上传文件,请使用UPLOAD");
    return ^BNHttpClient *(NSDictionary *fileDict){
        self.mFileDict = fileDict;
        return self;
    };
}

- (BNHttpClient *(^)(BOOL))DeBug {
    return ^BNHttpClient *(BOOL isDebug){
        self.isDebug = isDebug;
        return self;
    };
}

- (void)jsonData:(void(^)(id))jsonData {
    [self data:jsonData failure:nil always:nil];
}

- (void)data:(void (^)(id))data failure:(void (^)())failure {
    [self data:data failure:failure always:nil];
}

- (void)data:(void (^)(id))data failure:(void (^)())failure always:(void(^)())always{
    
    NSAssert(self.mUrl, @"未设置请求URL");
    
    //初始化请求客户端
    BNHttpClient *client = [[self class] manager];
    //设置请求
    [self setRequest:client];
    [self setHeader:client];
    //设置响应
    [self setResopnse:client];
    self.responseSerializer.acceptableContentTypes = self.acceptFormat;
    //设置url
    self.mUrl = [self filterUrl];
    
    //调试信息回调
    __weak typeof(self) weakSelf = self;
    void(^debugCallback)(NSString *) = ^(NSString *requestTypeStr){
#if DEBUG
        if (weakSelf.isDebug) {
            NSLog(@"#Warning#测试服务器:%@请求 URL:%@-参数:%@",requestTypeStr,weakSelf.mUrl,weakSelf.mParameters);
        }else {
            NSLog(@"%@请求 URL:%@-参数:%@",requestTypeStr,weakSelf.mUrl,weakSelf.mParameters);
        }
#endif
    };
    
    //完成回调
    void (^completeOperate)(id  _Nonnull responseObject) = ^(id  _Nonnull responseObject){
        if (data)data(responseObject);
        if(always) always();        
    };
    
    //失败回调
    void (^errorOperate)(NSError * _Nonnull error) = ^(NSError * _Nonnull error){
        NSLog(@"%@",error);
        if (failure)failure();
        if(always) always();
    };
    
    switch (self.mRequestType) {
        case GET:{
            debugCallback(@"GET");
            [client GET:self.mUrl parameters:self.mParameters success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
                completeOperate(responseObject);
            } failure:^(NSURLSessionDataTask * _Nonnull task, NSError * _Nonnull error) {
                errorOperate(error);
            }];
        }
            break;
        case POST:{
            debugCallback(@"POST");
            [client POST:self.mUrl parameters:self.mParameters success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
                completeOperate(responseObject);
            } failure:^(NSURLSessionDataTask * _Nonnull task, NSError * _Nonnull error) {
                errorOperate(error);
            }];
        }
            break;
        case UPLOAD:{
            debugCallback(@"UPLOAD");
            [client POST:self.mUrl parameters:self.mParameters constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
                NSAssert(self.mFileDict[@"data"], @"未设置data：文件数据");
                NSAssert(self.mFileDict[@"name"], @"未设置name：name参数");
                NSAssert(self.mFileDict[@"fileName"], @"未设置fileName：文件名称");
                NSAssert(self.mFileDict[@"fileType"], @"未设置fileType：文件格式");
                [formData appendPartWithFileData:self.mFileDict[@"data"] name:self.mFileDict[@"name"] fileName:self.mFileDict[@"fileName"] mimeType:self.mFileDict[@"fileType"]];
            } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
                completeOperate(responseObject);
            } failure:^(NSURLSessionDataTask * _Nonnull task, NSError * _Nonnull error) {
                errorOperate(error);
            }];
        }
            break;
    }
    [self update];
}

//过滤url
- (NSString *)filterUrl{
    
    //以http or https 开头的请求跳过过滤直接访问
    if ([self.mUrl hasPrefix:@"http://"] || [self.mUrl hasPrefix:@"https://"]) {
        return self.mUrl;
    }
    
    if (!DebugHost || !ServerHost) {
        NSLog(@"请设置主机地址");
        return @"";
    }
    
    NSString *host;
    if (self.isDebug) {//开启测试服务器
        host = DebugHost;
    }else {
        host = ServerHost;
    }
    
    //host结尾带"/"去掉尾巴   mUrl开头带"/"去掉头
    NSString *filterHostStr = [host hasSuffix:@"/"]?[host substringToIndex:host.length - 1]:host;
    NSString *filterUrlStr = [self.mUrl hasPrefix:@"/"]?[self.mUrl substringFromIndex:1]:self.mUrl;
    return [NSString stringWithFormat:@"%@/%@",filterHostStr,filterUrlStr];
}

//请求设置
- (void)setRequest:(BNHttpClient *)client {
    switch (client.mRequestSerializer) {
        case requestHttp:
            client.requestSerializer = [AFHTTPRequestSerializer serializer];
            break;
        case requestJson:
            client.requestSerializer = [AFJSONRequestSerializer serializer];
            break;
        default:
            break;
    }
}

//设置请求头信息
- (void)setHeader:(BNHttpClient *)client{
    if (!self.mHeader) return;
    [self.mHeader enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        [client.requestSerializer setValue:obj forHTTPHeaderField:key];
    }];
}

//响应设置
- (void)setResopnse:(BNHttpClient *)client {
    
    switch (client.mResponseSerializer) {
        case responseHttp:
            client.responseSerializer = [AFHTTPResponseSerializer serializer];
            break;
        case responseJson:
            client.responseSerializer = [AFJSONResponseSerializer serializer];
        default:
            break;
    }
}

//初始化默认参数
- (void)update {
    self.mUrl = nil;
    self.acceptFormat = self.responseSerializer.acceptableContentTypes;
    self.mRequestSerializer = requestHttp;
    self.mResponseSerializer = responseJson;
    self.mParameters = nil;
    self.mHeader = nil;
    self.isDebug = NO;
}

@end




BNHttpClient * BNHttp(NSString *type){
    return [BNHttpClient manager].setRequestType(type);
}

void BNGetJsonData(NSString *url,id param,void(^callBack)(id jsonData)) {
    [BNHttp(@"GET")
     .url(url)
     .params(param)
     jsonData:^(id data) {
         callBack(data);
     }];
}

