//
//  MJPhoto.h
//
//  Created by mj on 13-3-4.
//  Copyright (c) 2013年 itcast. All rights reserved.

#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>


@interface MJPhoto : NSObject
//@property (nonatomic, strong) NSURL *url;
//@property (nonatomic, strong) UIImage *image; // 完整的图片
@property (nonatomic, strong) ALAsset *asset;

@property (nonatomic) BOOL selected;
@property (nonatomic) BOOL overlay;

@property (nonatomic, strong) UIView *srcView; // 来源view
@property (nonatomic, strong, readonly) UIImage *capture;
@property (nonatomic, assign) BOOL firstShow;
@property (nonatomic, assign) int index; // 索引
@end