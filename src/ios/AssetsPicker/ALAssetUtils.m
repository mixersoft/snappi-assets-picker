//
//  ALAssetUtils.m
//  TestPlugin
//
//  Created by Donald Pae on 6/17/14.
//
//

#import "ALAssetUtils.h"

@implementation ALAssetUtils

+ (ALAssetsLibrary *)defaultAssetsLibrary
{
    static dispatch_once_t pred = 0;
    static ALAssetsLibrary *library = nil;
    dispatch_once(&pred,^
                  {
                      library = [[ALAssetsLibrary alloc] init];
                  });
    return library;
}

+ (void )getAssetsWithFromDate:(NSDate *)fromDate toDate:(NSDate *)toDate complete:(void (^)(NSArray *arrayAssets))complete
{
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    
    // add whole photos
    ALAssetsGroupEnumerationResultsBlock wholeBlock = ^(ALAsset *asset, NSUInteger index, BOOL *stop)
    {
        if (asset)
        {
            NSURL *url = [asset valueForProperty:ALAssetPropertyAssetURL];
            NSString *strUrl = [NSString stringWithFormat:@"%@", url.absoluteString];
            [dic setObject:asset forKey:strUrl];
        }
    };
    
    ALAssetsGroupEnumerationResultsBlock wholeLastBlock = ^(ALAsset *asset, NSUInteger index, BOOL *stop)
    {
        if (asset)
        {
            NSURL *url = [asset valueForProperty:ALAssetPropertyAssetURL];
            NSString *strUrl = [NSString stringWithFormat:@"%@", url.absoluteString];
            [dic setObject:asset forKey:strUrl];
        }
        else
        {
            // sort objeccts
            NSArray *sortedArray = [[dic allValues] sortedArrayUsingComparator:^NSComparisonResult(id a, id b)
                                    {
                                        ALAsset *assetA = (ALAsset *)a;
                                        ALAsset *other = (ALAsset *)b;
                                        NSComparisonResult ret = [[assetA valueForProperty:ALAssetPropertyDate] compare:[other valueForProperty:ALAssetPropertyDate]];
                                        return ret;
                                    }];
            
            NSMutableArray *resultArray = [[NSMutableArray alloc] init];
            
            BOOL bCompareFromDate = YES;
            BOOL bCompareToDate = YES;
            
            if (fromDate == nil)
                bCompareFromDate = NO;
            if (toDate == nil)
                bCompareToDate = NO;
            BOOL bStart = NO;
            
            for (ALAsset *asset in sortedArray) {
                NSDate *date = [asset valueForProperty:ALAssetPropertyDate];
                if (bStart == NO &&
                    (!bCompareFromDate || [date compare:fromDate] == NSOrderedDescending))
                    bStart = YES;
                
                if (bCompareToDate &&
                    [date compare:toDate] != NSOrderedAscending)
                    break;
                
                if (bStart)
                    [resultArray addObject:asset];
                
            }
            complete(resultArray);
        }
    };
    
    NSMutableArray *wholeGroups = [[NSMutableArray alloc] init];
    
    void (^ assetGroupEnumerator) ( ALAssetsGroup *, BOOL *)= ^(ALAssetsGroup *group, BOOL *stop) {
        if(group != nil) {
            [wholeGroups addObject:group];
        }
        else
        {
            for (int i = 0; i < wholeGroups.count - 1; i++) {
                ALAssetsGroup *group = [wholeGroups objectAtIndex:i];
                [group enumerateAssetsUsingBlock:wholeBlock];
            }
            
            if (wholeGroups.count >= 1)
            {
                ALAssetsGroup *group = [wholeGroups objectAtIndex:wholeGroups.count - 1];
                [group enumerateAssetsUsingBlock:wholeLastBlock];
            }
        }
    };
    
    [[ALAssetUtils defaultAssetsLibrary] enumerateGroupsWithTypes:ALAssetsGroupAll
                                             usingBlock:assetGroupEnumerator
                                           failureBlock:^(NSError *error) {NSLog(@"There is an error");}];
}

@end
