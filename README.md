# BNHttpClient

###这是一个链式调用的网络库，由ajax获得的一些灵感，封装了一些常用的操作。相比AFN的原生写法，更具有可定制性和灵活性。

```objc
AFHTTPSessionManager *mgr = [AFHTTPSessionManager manager];
//设置请求解析类型为HTTP
mgr.requestSerializer = [AFHTTPRequestSerializer serializer];
//设置请求头的键值对
[mgr.requestSerializer setValue:@"max-age=100" forHTTPHeaderField:@"cache-control"];
//设置响应解析类型为Json
mgr.responseSerializer = [AFJSONResponseSerializer serializer];
//设置响应可接收的格式
mgr.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"text/html",@"application/json", nil];
[mgr GET:@"http://www.xsdota.com" parameters:@{@"name":@"xiaos"} success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
        
} failure:^(NSURLSessionDataTask * _Nonnull task, NSError * _Nonnull error) {
        
}];
```

```objc
[BNHttp(@"GET")
.url(@"http://www.xsdota.com")
.param(@{@"name":@"xiaos"})
.addHttpHeader(@"cache-control",@"max-age=100")
.setRequestSerializer(@"http")
.setResponseSerializer(@"json")
.addAcceptFormat(@"text/html")
data:^(id data) {
   NSLog(@"success");
} failure:^{
   NSLog(@"failure");
} always:^{
   NSLog(@"always");
}];
```

BNHttp默认请求解析类型为http，响应解析类型为json。所以正常调用可以简化为

```objc
[BNHttp(@"GET")
.url(@"http://www.xsdota.com")
.param(@{@"name":@"xiaos"})
.addHttpHeader(@"cache-control",@"max-age=100")
.addAcceptFormat(@"text/html")
data:^(id data) {
   NSLog(@"success");
} failure:^{
   NSLog(@"failure");
} always:^{
   NSLog(@"always");
}];
```
AFN这种原生的调用暴露了太多语法细节，例如要设置一些参数得知道一些具体的类，修改这些类的属性或者方法来达到目的。
而链式调用的核心就将这些语法细节封装起来，不用知道底层到底是哪些类，只要知道一些通用的协议和规范就可以完成自己的目的。
简言而之，BNHttp有两大作用：
一是将离散的操作聚合起来，这样编程思路更加连贯，业务组织也更加灵活。
二是将语法细节封装起来，使用者更多的是考虑业务细节，而不是底层的代码组织。


