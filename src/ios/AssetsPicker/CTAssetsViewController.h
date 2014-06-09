/*
 CTAssetsViewController.h
 
 The MIT License (MIT)
 
 Copyright (c) 2013 Clement CN Tsang
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 
 */

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "CTAsset.h"

@class CTAssetsPickerController;

typedef enum {
    CTAssetsViewTypeNormal = 0,
    CTAssetsViewTypeFiltered = 1,
    CTAssetsViewTypeBookmarks = 2
}CTAssetsViewType;

@protocol CTAssetsViewControllerDelegate <NSObject>

- (void) tapAsset:(CTAsset *)ctasset;

@end

@interface CTAssetsViewController : UICollectionViewController<UIGestureRecognizerDelegate, CTAssetsViewControllerDelegate>

@property (nonatomic) CTAssetsViewType  viewType;
@property (nonatomic, strong) ALAssetsGroup *assetsGroup;
@property (nonatomic, strong) NSMutableArray *assets;
@property (nonatomic) BOOL bShowFirst;
@property (nonatomic) BOOL isLoading;


- (id)initWithType:(CTAssetsViewType)type withPicker:(CTAssetsPickerController *)picker;

- (void)setupAssetsForAlbum:(ALAssetsGroup *)group withCompletion:(void(^)())block;
- (void)setupSelectedAssetsWithCompletion:(void(^)())block;
- (void)setupWholeAssetsWithCompletion:(void(^)())block;

@end