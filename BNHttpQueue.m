//
//  BNHttpQueue.m
//  BNHttpClientProject
//
//  Created by xiaos on 16/8/17.
//  Copyright © 2016年 com.xsdota. All rights reserved.
//

#import "BNHttpQueue.h"
#import "HttpClient.h"

@implementation BNHttpQueue
- (instancetype)initWithRequestType:(NSString *)type
                                url:(NSString *)url
                              param:(id)param
                           resultId:(NSString *)resultId {
    BNHttpQueue *queue = [BNHttpQueue new];
    queue.requestType = type;
    queue.url = url;
    queue.param = param;
    queue.resultId = resultId;
    return queue;
}
@end

@interface BNHttpTarget ()
@property (nonatomic,copy) NSArray<BNHttpQueue *> *queues;     ///< 请求队列
@property (nonatomic,strong) NSMutableDictionary *result;      ///< 最终结果
@property (nonatomic,assign) NSUInteger completeCount;         ///< 已完成请求计数
@property (nonatomic,assign) void(^successBlock)(NSDictionary *results); ///< 全部请求成功
@property (nonatomic,assign) void(^someBlock)(NSDictionary *someResults);    ///< 部分请求成功
@end

@implementation BNHttpTarget

- (void)dealloc {
    [self removeObserver:self forKeyPath:@"completeCount"];
}

- (instancetype)initWithQueue:(NSArray<BNHttpQueue *> *)qs
                      success:(void(^)(NSDictionary *))success
                               some:(void(^)(NSDictionary *))some{
    if (self = [super init]) {
        self.completeCount = 0;
        self.queues = qs;
        self.result = [[NSMutableDictionary alloc] initWithCapacity:qs.count];
        self.successBlock = success;
        self.someBlock = some;
        [self loadData];
    }
    return self;
}

- (void)loadData{
    
    //信号量与KVO 实现多个并发异步请求完毕后接收回调
    [self addObserver:self forKeyPath:@"completeCount" options:NSKeyValueObservingOptionNew context:nil];
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(1);
    
    __weak typeof(self) weakSelf = self;
    
    for (NSInteger i = 0; i < self.queues.count; i++) {
        BNHttpQueue *queue = self.queues[i];
        
        [BNHttp(queue.requestType)
         .url(queue.url)
         .params(queue.param)
         data:^(id response) {
             weakSelf.result[queue.resultId] = response;
         } failure:nil always:^{
             dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
             weakSelf.completeCount++;
             dispatch_semaphore_signal(semaphore);
         }];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    NSUInteger queuesCount = self.queues.count;
    
    
    if ([keyPath isEqualToString:@"completeCount"]) {
        if ([change[@"new"] isEqual:@(queuesCount)]) {//所以请求都完成
            if (self.result.count == self.queues.count) {
                if(self.successBlock){
                    self.successBlock([self.result copy]);
                }
            }else {
                if (self.someBlock) {
                    self.someBlock([self.result copy]);
                }                
            }
        }
    }
}

- (BOOL)isAllSuccess {
    return [[self.result copy] count] == self.completeCount;
}

@end