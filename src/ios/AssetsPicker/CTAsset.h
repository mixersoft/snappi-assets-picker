//
//  CTAsset.h
//  TestPlugin
//
//  Created by Donald Pae on 6/9/14.
//
//

#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

@interface CTAsset : NSObject

@property (nonatomic, strong) ALAsset *asset;
@property (nonatomic) int index;

@end
