//
//  Request.h
//  Jide
//
//  Created by jingzhao on 2018/11/8.
//  Copyright © 2018 jide. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AFNetworking.h>
//无网络
#define NOT_NETWORK_ERROR [NSError errorWithDomain:@"com.shequren.SQRNetworking.ErrorDomain" code:-999 userInfo:@{NSLocalizedDescriptionKey:@"无网络"}]

//请求成功处理数据并返回
#define REQUEST_SUCCEED_OPERATION_BLCOK(success)\
\
NSDictionary *dictObj;\
if ([responseObject isKindOfClass:[NSDictionary class]]) {\
if (success)success(responseObject);\
NSLog(@"成功返回 --- URL ： %@ \n %@",urlString,responseObject);\
}else{\
NSString *responseJson = [[NSString alloc]initWithData:responseObject encoding:NSUTF8StringEncoding];\
dictObj = [responseJson jsonValueDecoded];\
if (success)success(dictObj);\
NSLog(@"成功返回 --- URL ： %@ \n %@",urlString,dictObj);\
}\
[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];\
//[MBProgressHUD hideAllHUDsForView:DEF_Window animated:YES];\


//请求成功判断缓存方式并缓存
#define SAVECACHEWITH_CACHEWAY_MYCHAHE_KEY(cacheWay,myCache,cacheKey)\
dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{\
if (cacheWay != IgnoringLocalCacheData) {\
if ([responseObject isKindOfClass:[NSDictionary class]]) {\
[myCache setObject:responseObject forKey:cacheKey];\
}else{\
[myCache setObject:dictObj forKey:cacheKey];\
}\
}\
});


typedef NS_ENUM(NSUInteger, NetworkMethod) {
    GET = 0,
    POST,
    PUT,
    DELETE,
    PATCH
};
typedef NS_ENUM(NSUInteger, RequestCachePolicy) {
    /** 正在刷新中的状态 */
    CacheDataThenLoad = 0,                                                      // 有缓存就先返回缓存，同步请求数据
    IgnoringLocalCacheData,                                                     // 忽略缓存，重新请求
    CacheDataElseLoad,                                                          // 有缓存就用缓存，没有缓存就重新请求(用于数据不变时)
    CacheDataDontLoad,                                                          // 有缓存就用缓存，没有缓存就不发请求，当做请求出错处理（用于离线模式）
};
typedef void (^NetRequestSuccessBlock)(id responseObject);                      //成功Block
typedef void (^NetRequestCacheSuccessBlock)(id responseObject, BOOL isCache);   //缓存成功Block
typedef void (^NetRequestFailedBlock)(NSError *error,NSURLSessionDataTask *task);//失败Block
typedef void (^NetRequestProgressBlock)(float progress);                        //进度Block
typedef void (^NetResponseCache)(id responseObject);
@interface Request : NSObject
+(Request*)shareRequest;
/**
 *  当前的网络状态
 */
@property (nonatomic, assign) AFNetworkReachabilityStatus AFNetWorkStatus;
/**
 *  请求者
 */
@property (nonatomic, strong) AFHTTPSessionManager *sharedManager;

/**
 请求

 @param urlString url
 @param parameters 参数
 @param type 请求类型
 @param policy 缓存策略
 @param success 成功
 @param cache 缓存
 @param fail 失败
 */
- (void)requestWithUrl:(NSString *)urlString
            parameters:(id)parameters
                  type:(NetworkMethod)type
           cachePolicy:(RequestCachePolicy)policy
               success:(NetRequestSuccessBlock)success
                 cache:(NetResponseCache)cache
               failure:(NetRequestFailedBlock)fail;
/**
 *  Get形式提交数据
 *
 *  @param urlString  Url
 *  @param parameters 参数
 *  @param success    成功Block
 *  @param fail       失败Block
 */
- (void)getWithUrl:(NSString *)urlString
        parameters:(id)parameters
           success:(NetRequestSuccessBlock)success
              fail:(NetRequestFailedBlock)fail;


/**
 *  Post形式提交数据
 *
 *  @param urlString  Url
 *  @param parameters 参数
 *  @param success    成功Block
 *  @param fail       失败Block
 */
- (void)postWithUrl:(NSString *)urlString
         parameters:(id)parameters
            success:(NetRequestSuccessBlock)success
               fail:(NetRequestFailedBlock)fail;

/**
 *  Put形式提交数据
 *
 *  @param urlString  Url
 *  @param parameters 参数
 *  @param success    成功Block
 *  @param fail       失败Block
 */
- (void)putWithUrl:(NSString *)urlString
        parameters:(id)parameters
           success:(NetRequestSuccessBlock)success
              fail:(NetRequestFailedBlock)fail;

/**
 *  Delete形式提交数据
 *
 *  @param urlString  Url
 *  @param parameters 参数
 *  @param success    成功Block
 *  @param fail       失败Block
 */
- (void)deleteWithUrl:(NSString *)urlString
           parameters:(id)parameters
              success:(NetRequestSuccessBlock)success
                 fail:(NetRequestFailedBlock)fail;
/**
 *  Patch形式提交数据
 *
 *  @param urlString  Url
 *  @param parameters 参数
 *  @param success    成功Block
 *  @param fail       失败Block
 */
- (void)patchWithUrl:(NSString *)urlString
          parameters:(id)parameters
             success:(NetRequestSuccessBlock)success
                fail:(NetRequestFailedBlock)fail;
/**
 *  POST上传图片
 *
 *  @param urlString  上传地址
 *  @param image      图片
 *  @param parameters 参数
 *  @param success    成功Block
 *  @param fail       失败Block
 */
- (void)postUploadImageWithUrl:(NSString *)urlString
                         image:(UIImage *)image
                    parameters:(id)parameters
                      progress:(NetRequestProgressBlock)progress
                       success:(NetRequestSuccessBlock)success
                          fail:(NetRequestFailedBlock)fail;

@end
