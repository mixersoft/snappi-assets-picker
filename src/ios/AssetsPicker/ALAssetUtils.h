//
//  ALAssetUtils.h
//  TestPlugin
//
//  Created by Donald Pae on 6/17/14.
//
//

#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>


@interface ALAssetUtils : NSObject

+ (ALAssetsLibrary *)defaultAssetsLibrary;

+ (void )getAssetsWithFromDate:(NSDate *)fromDate toDate:(NSDate *)toDate complete:(void (^)(NSArray *arrayAssets))complete;

@end
