//
//  Request.m
//  Jide
//
//  Created by jingzhao on 2018/11/8.
//  Copyright © 2018 jide. All rights reserved.
//

#import "Request.h"
#import "YYCache.h"

static AFNetworkReachabilityStatus  networkStatus; //网络状态

@implementation Request
+(Request *)shareRequest{
    static Request *request = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        request = [[Request alloc] init];
        [self checkNetworkStatus];
    });
    return request;
}
- (AFHTTPSessionManager *)sharedManager {
    static AFHTTPSessionManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [AFHTTPSessionManager manager];
        manager.responseSerializer.acceptableContentTypes = [NSSet setWithArray:@[@"application/json",
                                                                                  @"text/html",
                                                                                  @"text/json",
                                                                                  @"text/plain",
                                                                                  @"text/javascript",
                                                                                  @"text/xml",
                                                                                  @"image/*",
                                                                                  @"application/octet-stream",
                                                                                  @"application/zip"]];
        manager.requestSerializer.timeoutInterval = 10;
    });
    return manager;
}

#pragma mark --- 检查网络
+ (void)checkNetworkStatus {
    networkStatus = AFNetworkReachabilityStatusUnknown;
    AFNetworkReachabilityManager *manager = [AFNetworkReachabilityManager sharedManager];
    [manager startMonitoring];
    [manager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        switch (status) {
            case AFNetworkReachabilityStatusUnknown:
            {
                // 未知网络
                networkStatus = AFNetworkReachabilityStatusUnknown;
            }
                break;
            case AFNetworkReachabilityStatusNotReachable:
            {
                // 没有网络
                networkStatus = AFNetworkReachabilityStatusNotReachable;
            }
                break;
            case AFNetworkReachabilityStatusReachableViaWWAN:
            {
                // 手机自带网络,移动流量
                networkStatus = AFNetworkReachabilityStatusReachableViaWWAN;
            }
                break;
            case AFNetworkReachabilityStatusReachableViaWiFi:
            {
                // WIFI
                networkStatus = AFNetworkReachabilityStatusReachableViaWiFi;
            }
        }
    }];
    
}
- (void)requestWithUrl:(NSString *)urlString
            parameters:(id)parameters
                  type:(NetworkMethod)type
           cachePolicy:(RequestCachePolicy)policy
               success:(NetRequestSuccessBlock)success
                 cache:(NetResponseCache)cache
               failure:(NetRequestFailedBlock)fail
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        
    });
    
    AFHTTPSessionManager *manager = [self sharedManager];
    
    //判断接口类型，处理不同设置
    manager.requestSerializer = [AFHTTPRequestSerializer serializer];
    if (networkStatus == AFNetworkReachabilityStatusNotReachable) {
        if (fail)fail(NOT_NETWORK_ERROR,nil);
        return;
    }
    
    NSLog(@"发起请求 --- URL ： %@",urlString);
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    //缓存，用url拼接参数作为key
    YYCache *myCache = [YYCache cacheWithName:@"DKCache"];
    NSString *parString = parameters ? [parameters modelToJSONString] : @"";
    NSString *cacheKey = [NSString stringWithFormat:@"%@%@", urlString, parString];
    
    if (cache) {
        //获取缓存
        id object = [myCache objectForKey:cacheKey];
        switch (policy) {
                
                //先返回缓存，同时请求
            case CacheDataThenLoad: {
                if (object)cache(object);
                break;
            }
                
                //忽略本地缓存直接请求
            case IgnoringLocalCacheData: {
                break;
            }
                
                //有缓存就返回缓存，没有就请求
            case CacheDataElseLoad: {
                if (object) {
                    cache(object);
                    return ;
                }
                break;
            }
                
                //有缓存就返回缓存,从不请求（用于没有网络）
            case CacheDataDontLoad: {
                if (object)cache(object);
                return ;
            }
            default: {
                break;
            }
        }
    }
    
    
    switch (type) {
        case GET: {
            
            [manager GET:urlString parameters:parameters progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                REQUEST_SUCCEED_OPERATION_BLCOK(success);
                SAVECACHEWITH_CACHEWAY_MYCHAHE_KEY(policy,myCache,cacheKey);
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                
                [self requestDisposeUrl:urlString parameters:parameters type:type  cachePolicy:policy success:success cache:cache failure:fail error:error task:task];
                
            }];
        }
            break;
            
        case POST: {
            
            [manager POST:urlString parameters:parameters progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                
                REQUEST_SUCCEED_OPERATION_BLCOK(success);
                SAVECACHEWITH_CACHEWAY_MYCHAHE_KEY(policy,myCache,cacheKey);
                
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                
                [self requestDisposeUrl:urlString parameters:parameters type:type cachePolicy:policy success:success cache:cache failure:fail error:error task:task];
                
            }];
        }
            break;
            
        case PUT: {
            [manager PUT:urlString parameters:parameters success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                
                REQUEST_SUCCEED_OPERATION_BLCOK(success);
                
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                
                [self requestDisposeUrl:urlString parameters:parameters type:type cachePolicy:policy success:success cache:cache failure:fail error:error task:task];
                
            }];
        }
            break;
            
        case DELETE: {
            [manager DELETE:urlString parameters:parameters success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                
                REQUEST_SUCCEED_OPERATION_BLCOK(success);
                
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                
                [self requestDisposeUrl:urlString parameters:parameters type:type cachePolicy:policy success:success cache:cache failure:fail error:error task:task];
                
            }];
        }
            break;
            
        case PATCH: {
            [manager PATCH:urlString parameters:parameters success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                
                REQUEST_SUCCEED_OPERATION_BLCOK(success);
                
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                
                [self requestDisposeUrl:urlString parameters:parameters type:type  cachePolicy:policy success:success cache:cache failure:fail error:error task:task];
                
            }];
        }
            break;
            
        default:
            break;
    }
}

- (void)getWithUrl:(NSString *)urlString
        parameters:(id)parameters
           success:(NetRequestSuccessBlock)success
              fail:(NetRequestFailedBlock)fail
{
    [self requestWithUrl:urlString parameters:parameters type:GET cachePolicy:IgnoringLocalCacheData success:success cache:nil failure:fail];
}
- (void)postWithUrl:(NSString *)urlString
         parameters:(id)parameters
            success:(NetRequestSuccessBlock)success
               fail:(NetRequestFailedBlock)fail
{
    [self requestWithUrl:urlString parameters:parameters type:POST  cachePolicy:IgnoringLocalCacheData success:success cache:nil failure:fail];
}

- (void)putWithUrl:(NSString *)urlString
        parameters:(id)parameters
           success:(NetRequestSuccessBlock)success
              fail:(NetRequestFailedBlock)fail
{
    [self requestWithUrl:urlString parameters:parameters type:PUT cachePolicy:IgnoringLocalCacheData success:success cache:nil failure:fail];
}


- (void)deleteWithUrl:(NSString *)urlString
           parameters:(id)parameters
              success:(NetRequestSuccessBlock)success
                 fail:(NetRequestFailedBlock)fail
{
    [self requestWithUrl:urlString parameters:parameters type:DELETE cachePolicy:IgnoringLocalCacheData success:success cache:nil failure:fail];
}
- (void)patchWithUrl:(NSString *)urlString
          parameters:(id)parameters
             success:(NetRequestSuccessBlock)success
                fail:(NetRequestFailedBlock)fail
{
    [self requestWithUrl:urlString parameters:parameters type:PATCH  cachePolicy:IgnoringLocalCacheData success:success cache:nil failure:fail];
}
- (void)postUploadImageWithUrl:(NSString *)urlString
                         image:(UIImage *)image
                    parameters:(id)parameters
                      progress:(NetRequestProgressBlock)progress
                       success:(NetRequestSuccessBlock)success
                          fail:(NetRequestFailedBlock)fail
{
    AFHTTPSessionManager *manager = [self sharedManager];

    if (networkStatus == AFNetworkReachabilityStatusNotReachable) {
        if (fail)fail(NOT_NETWORK_ERROR,nil);
        return;
    }
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [manager POST:urlString parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        //        NSData *imageData = UIImagePNGRepresentation(image);
        NSData *imageData = [self compressWithMaxLength:600000 image:image];
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"yyyyMMddHHmmss";
        NSString *str = [formatter stringFromDate:[NSDate date]];
        NSString *fileName = [NSString stringWithFormat:@"%@.jpg",[NSString stringWithFormat:@"%@.jpg", str]];
        [formData appendPartWithFileData:imageData name:@"img" fileName:fileName mimeType:@"image/jpg"];
        
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        
        if (progress)progress(uploadProgress.fractionCompleted);
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        REQUEST_SUCCEED_OPERATION_BLCOK(success);
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        fail(error,task);
        
    }];
}
//错误处理
- (void)requestDisposeUrl:(NSString *)url
               parameters:(id)parameters
                     type:(NetworkMethod)type
              cachePolicy:(RequestCachePolicy)policy
                  success:(NetRequestSuccessBlock)success
                    cache:(NetResponseCache)cache
                  failure:(NetRequestFailedBlock)fail
                    error:(NSError * _Nonnull)error
                     task:(NSURLSessionDataTask * _Nullable)task {
    
    if (fail)fail(error,task);
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    NSHTTPURLResponse * responses = (NSHTTPURLResponse *)task.response;
    NSLog(@"失败返回 --- URL ： %@ \n ---错误码 = %ld  \n ---详细信息 : %@",url,responses.statusCode,error);
    
   
}
-(NSData *)compressWithMaxLength:(NSUInteger)maxLength image:(UIImage*)image{
    // Compress by quality
    CGFloat compression = 1;
    NSData *data = UIImageJPEGRepresentation(image, compression);
    //NSLog(@"Before compressing quality, image size = %ld KB",data.length/1024);
    if (data.length < maxLength) return data;
    
    CGFloat max = 1;
    CGFloat min = 0;
    for (int i = 0; i < 6; ++i) {
        compression = (max + min) / 2;
        data = UIImageJPEGRepresentation(image, compression);
        //NSLog(@"Compression = %.1f", compression);
        //NSLog(@"In compressing quality loop, image size = %ld KB", data.length / 1024);
        if (data.length < maxLength * 0.9) {
            min = compression;
        } else if (data.length > maxLength) {
            max = compression;
        } else {
            break;
        }
    }
    //NSLog(@"After compressing quality, image size = %ld KB", data.length / 1024);
    if (data.length < maxLength) return data;
    UIImage *resultImage = [UIImage imageWithData:data];
    // Compress by size
    NSUInteger lastDataLength = 0;
    while (data.length > maxLength && data.length != lastDataLength) {
        lastDataLength = data.length;
        CGFloat ratio = (CGFloat)maxLength / data.length;
        //NSLog(@"Ratio = %.1f", ratio);
        CGSize size = CGSizeMake((NSUInteger)(resultImage.size.width * sqrtf(ratio)),
                                 (NSUInteger)(resultImage.size.height * sqrtf(ratio))); // Use NSUInteger to prevent white blank
        UIGraphicsBeginImageContext(size);
        [resultImage drawInRect:CGRectMake(0, 0, size.width, size.height)];
        resultImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        data = UIImageJPEGRepresentation(resultImage, compression);
        //NSLog(@"In compressing size loop, image size = %ld KB", data.length / 1024);
    }
    //NSLog(@"After compressing size loop, image size = %ld KB", data.length / 1024);
    return data;
}

@end
