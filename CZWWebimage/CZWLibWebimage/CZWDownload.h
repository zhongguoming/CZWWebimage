//
//  CZWDownload.h
//  CZWWebimage
//
//  Created by dingdang on 2019/4/10.
//  Copyright © 2019 dingdang. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^DownloadBlock) (UIImage *);

@interface CZWDownload : NSObject


/**
 下载图片

 @param urlStr 下载地址
 @param downloadBlock 完成下载回调，返回下载图片
 */
+ (void)downloadImageWithUrlStr:(NSString *)urlStr completionHandler:(DownloadBlock)downloadBlock;

@end

