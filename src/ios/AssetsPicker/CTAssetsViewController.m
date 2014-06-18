/*
 CTAssetsViewController.m
 
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

#import "CTAssetsPickerConstants.h"
#import "CTAssetsPickerController.h"
#import "CTAssetsViewController.h"
#import "CTAssetsViewCell.h"
#import "CTAssetsSupplementaryView.h"

#import "MJPhotoBrowser.h"
#import "MJPhoto.h"

#import "FloatingTrayView.h"
#import "CTAsset.h"
#import "ALAsset+isEqual.h"
#import "SVProgressHUD.h"



NSString * const CTAssetsViewCellIdentifier = @"CTAssetsViewCellIdentifier";
NSString * const CTAssetsSupplementaryViewIdentifier = @"CTAssetsSupplementaryViewIdentifier";


@interface CTAssetsPickerController()

@property (nonatomic, strong) UIBarButtonItem *titleButton;
@property (nonatomic, strong) ALAssetsLibrary *assetsLibrary;

- (void)finishPickingAssets:(id)sender;
- (void)setActionForTitleButton:(BOOL)bSet;

- (NSString *)toolbarTitle;
- (UIView *)noAssetsView;

- (void)dismiss:(id)sender;

@end



@interface CTAssetsViewController () <FloatingTrayDelegate>

@property (nonatomic, weak) CTAssetsPickerController *picker;
@property (nonatomic, strong) NSMutableArray *photos;
@property (nonatomic, strong) CTAsset *previousAsset;


@property (nonatomic, strong) FloatingTrayView* floatingTrayView;

@end


@implementation CTAssetsViewController


- (id)initWithType:(CTAssetsViewType)type withPicker:(CTAssetsPickerController *)picker;
{
    self.picker = picker;
    
    UICollectionViewFlowLayout *layout = [self collectionViewFlowLayoutOfOrientation:self.interfaceOrientation];
    
    if (self = [super initWithCollectionViewLayout:layout])
    {
        self.viewType = type;
        self.collectionView.allowsMultipleSelection = YES;
        
        [self.collectionView registerClass:CTAssetsViewCell.class
                forCellWithReuseIdentifier:CTAssetsViewCellIdentifier];
        
        [self.collectionView registerClass:CTAssetsSupplementaryView.class
                forSupplementaryViewOfKind:UICollectionElementKindSectionFooter
                       withReuseIdentifier:CTAssetsSupplementaryViewIdentifier];
        
        self.preferredContentSize = kPopoverContentSize;
        self.bShowFirst = YES;
        self.isLoading = YES;

    }
    
    [self addNotificationObserver];
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupViews];
    
    // attach long press gesture to collectionView
    UILongPressGestureRecognizer *lpgr
    = [[UILongPressGestureRecognizer alloc]
       initWithTarget:self action:@selector(handleLongPress:)];
    lpgr.minimumPressDuration = .5; //seconds
    lpgr.delaysTouchesBegan = YES;
    lpgr.delegate = self;
    [self.collectionView addGestureRecognizer:lpgr];

    // hide the status bar
    //[[UIApplication sharedApplication]setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];

}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self setupButtons];
    [self setupToolbar];
    [self setupTitle];

    if (!self.assets)
    {
        if (self.viewType == CTAssetsViewTypeBookmarks)
        {
            //[SVProgressHUD showWithStatus:@"Loading"];
            self.isLoading = YES;
            [self setupWholeAssetsWithCompletion:^(){
                [self reloadData];
                self.isLoading = NO;
            }];
        }
    }
    else
    {
        if (self.bShowFirst)
            [self scrollToPrevious];
        else
            [self.collectionView reloadData];
        self.bShowFirst = NO;
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
  
    switch (self.viewType) {
        case CTAssetsViewTypeNormal:
        {
            // set previous album/asset
            
            NSURL *url = [self.assetsGroup valueForProperty:ALAssetsGroupPropertyURL];
            NSString *strUrl = [NSString stringWithFormat:@"%@", [url absoluteString]];
            
            
            // set previous assets as (upper left corner item)
            NSIndexPath *indexPath = [self indexPathForUpperLeftItem];
            if (indexPath)
            {
                CTAssetsViewCell *cell = (CTAssetsViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
                
                CTAsset *ctasset = cell.ctasset;
                url = [ctasset.asset valueForProperty:ALAssetPropertyAssetURL];
                NSString *strAssetsUrl = [NSString stringWithFormat:@"%@", [url absoluteString]];
                
                [self.picker.previousAssets setObject:strAssetsUrl forKey:strUrl];
                
                self.previousAsset = ctasset;
            }
            else
            {
                [self.picker.previousAssets removeObjectForKey:strUrl];
                self.previousAsset = nil;
            }
        }
            break;
            
        case CTAssetsViewTypeFiltered:
            [self.picker setActionForTitleButton:YES];
            break;
            
        case CTAssetsViewTypeBookmarks:
            break;
        default:
            break;
    }
    
}

- (void)dealloc
{
    [self removeNotificationObserver];
}


#pragma mark - Accessors


#pragma mark - Rotation

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    UICollectionViewFlowLayout *layout = [self collectionViewFlowLayoutOfOrientation:toInterfaceOrientation];
    [self.collectionView setCollectionViewLayout:layout animated:YES];
}


#pragma mark - Setup

- (void)setupViews
{
    self.collectionView.backgroundColor = [UIColor whiteColor];
    
    
    // setup floating view
    
    switch (self.viewType) {
        case CTAssetsViewTypeNormal:
            //
            break;
            
        case CTAssetsViewTypeFiltered:
            break;
            
        case CTAssetsViewTypeBookmarks:
            self.floatingTrayView = [[FloatingTrayView alloc] initWithFrame:CGRectZero];
            self.floatingTrayView.delegate = self;
            [self.view addSubview:self.floatingTrayView];
            
            [self.floatingTrayView installConstraints];
            self.floatingTrayView.hidden = NO;
            
            break;
            
        default:
            break;
    }
}

- (void)setupButtons
{
    switch (self.viewType) {
        case CTAssetsViewTypeNormal:
        case CTAssetsViewTypeFiltered:
            //
            break;
            
        case CTAssetsViewTypeBookmarks:
            if (self.picker.showsCancelButton)
            {
                self.navigationItem.leftBarButtonItem =
                [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", nil)
                                                 style:UIBarButtonItemStylePlain
                                                target:self.picker
                                                action:@selector(dismiss:)];
            }
            break;
            
        default:
            break;
    }
    
    
    self.navigationItem.rightBarButtonItem =
    [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done", nil)
                                     style:UIBarButtonItemStyleDone
                                    target:self.picker
                                    action:@selector(finishPickingAssets:)];
    
    self.navigationItem.rightBarButtonItem.enabled = (self.picker.selectedAssets.count > 0);
}

- (void)setupToolbar
{
    self.toolbarItems = self.picker.toolbarItems;

}

- (void)setupTitle
{
    // title of view
    switch (self.viewType) {
        case CTAssetsViewTypeNormal:
            self.title = [self.assetsGroup valueForProperty:ALAssetsGroupPropertyName];
            break;
        case CTAssetsViewTypeFiltered:
            self.title = [NSString stringWithFormat:@"Selected Photos"];
            [self.picker setActionForTitleButton:NO];
            
        case CTAssetsViewTypeBookmarks:
            self.title = [NSString stringWithFormat:@"All Photos"];
            break;
            
        default:
            break;
    }

}

#pragma mark Setup Photos
- (void)setupPhotos
{
    if (self.assets.count > 0)
    {
        self.photos = [NSMutableArray arrayWithCapacity:self.assets.count];
        // 1.create photo datas
        for (int i = 0; i < self.assets.count; i++) {
            // 替换为中等尺寸图片
            MJPhoto *photo = [[MJPhoto alloc] init];
            CTAsset *ctasset = [self.assets objectAtIndex:i];
            photo.ctasset = ctasset;
            [self.photos addObject:photo];
            
            NSIndexPath *path = [NSIndexPath indexPathForItem:i inSection:0];
            UICollectionViewCell *theCell = [self.collectionView cellForItemAtIndexPath:path];
            photo.srcView = theCell;
        }
    }
    else
        self.photos = [[NSMutableArray alloc] init];
}

#pragma mark Setup Assets

- (void)setupAssetsForAlbum:(ALAssetsGroup *)group withCompletion:(void(^)())block {
    
    self.isLoading = YES;
    
    self.assets = [[NSMutableArray alloc] init];
    
    NSURL *groupUrl = [self.assetsGroup valueForProperty:ALAssetsGroupPropertyURL];
    NSString *strGroupUrl = [NSString stringWithFormat:@"%@", [groupUrl absoluteString]];
    
    NSString *previousUrl = [self.picker.previousAssets objectForKey:strGroupUrl];
    
    if (previousUrl != nil && ![previousUrl isEqualToString:@""])
    {
        [self.picker.assetsLibrary assetForURL:[NSURL URLWithString:previousUrl] resultBlock:^(ALAsset *asset) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (asset != nil)
                {
                    self.previousAsset = nil;
                    for (CTAsset *ctasset in self.assets) {
                        if ([ctasset.asset isEqual:asset])
                        {
                            self.previousAsset = ctasset;
                            break;
                        }
                    }
                    if (self.previousAsset)
                    {
                        NSUInteger index = self.previousAsset.index;
                        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:0];
                        [self scrollToIndexPath:indexPath animated:NO];
                    }
                    
                }
            });
        } failureBlock:^(NSError *error) {
        }];
    }
    
    
    // add album photos
    __block int i = 0;
    ALAssetsGroupEnumerationResultsBlock albumBlock = ^(ALAsset *asset, NSUInteger index, BOOL *stop)
    {
        
        if (asset)
        {
            CTAsset *ctasset = [[CTAsset alloc] init];
            ctasset.asset = asset;
            ctasset.index = i;
            [self.assets addObject:ctasset];
            i++;
        }
        else
        {
            [self setupPhotos];
            
            self.isLoading = NO;
            
            if (block)
                block();
        }
    };
    
    [group enumerateAssetsUsingBlock:albumBlock];
}

- (void)setupSelectedAssetsWithCompletion:(void(^)())block {
    
    self.isLoading = YES;
    self.assets = [[NSMutableArray alloc] init];
    
    
    // sort objeccts
    NSArray *sortedArray = [self.picker.selectedAssets sortedArrayUsingComparator:^NSComparisonResult(id a, id b)
                            {
                                ALAsset *assetA = (ALAsset *)a;
                                ALAsset *other = (ALAsset *)b;
                                NSComparisonResult ret = [[assetA valueForProperty:ALAssetPropertyDate] compare:[other valueForProperty:ALAssetPropertyDate]];
                                return ret;
                            }];
    int i = 0;
    for (ALAsset *asset in sortedArray) {
        CTAsset *ctasset = [[CTAsset alloc] init];
        ctasset.asset = asset;
        ctasset.index = i;
        [self.assets addObject:ctasset];
        i++;
    }
    
    [self setupPhotos];
    
    self.isLoading = NO;
    
    if (block)
        block();
}

- (void)setupWholeAssetsWithCompletion:(void(^)())block {

    self.isLoading = YES;
    self.assets = [[NSMutableArray alloc] init];

#if true
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
            
            int i = 0;
            for (ALAsset *asset in sortedArray) {
                CTAsset *ctasset = [[CTAsset alloc] init];
                ctasset.asset = asset;
                ctasset.index = i;
                [self.assets addObject:ctasset];
                i++;
            }
            
            [self setupPhotos];
            
            self.isLoading = NO;
            
            if (block)
                block();
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
    
    [self.picker.assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupAll
                                             usingBlock:assetGroupEnumerator
                                           failureBlock:^(NSError *error) {NSLog(@"There is an error");}];
#else
    
    NSMutableArray *array = [[NSMutableArray alloc] init];
    NSMutableArray *arrayDates = [[NSMutableArray alloc] init];
    NSMutableArray *wholeGroups = [[NSMutableArray alloc] init];
    
    
    ALAssetsGroupEnumerationResultsBlock wholeLastBlock = ^(ALAsset *asset, NSUInteger index, BOOL *stop)
    {
        if (asset)
        {
            //NSURL *url = [asset valueForProperty:ALAssetPropertyAssetURL];
            //NSString *strUrl = [NSString stringWithFormat:@"%@", url.absoluteString];
            [array addObject:asset];
            [arrayDates addObject:[asset valueForProperty:ALAssetPropertyDate]];
        }
        else
        {
            /** sort object */
            
            if (wholeGroups.count > 1)
            {
                int arrayPicks[100];
                int countPicks[100];
                int segCount = 0;
                
                ALAsset *prevAsset = nil;
                int prevIndex = 0;
                
                arrayPicks[segCount] = 0;
                
                for (int i = 1; i < array.count; i++) {
                    prevAsset = [array objectAtIndex:i - 1];
                    //ALAsset *asset = [array objectAtIndex:i];
                    //NSDate *prevDate = [asset valueForProperty:ALAssetPropertyDate];
                    //NSDate *date = [asset valueForProperty:ALAssetPropertyDate];
                    NSDate *prevDate = [arrayDates objectAtIndex:i - 1];
                    NSDate *date = [arrayDates objectAtIndex:i];
                    
                    if (!([prevDate compare:date] == NSOrderedSame ||
                        [prevDate compare:date] == NSOrderedAscending))
                    {
                        arrayPicks[segCount + 1] = i;
                        countPicks[segCount] = i - prevIndex;
                        segCount++;
                        prevIndex = i;
                    }
                }
                
                countPicks[segCount] = array.count - prevIndex;
                segCount++;
                
                NSMutableArray *resultArray = nil;
                NSMutableArray *resultDateArray = nil;
                
                if (segCount <= 1)
                {
                    resultArray = array;
                    resultDateArray = arrayDates;
                }
                else
                {
                    NSMutableArray *newArray = [[NSMutableArray alloc] init];
                    NSMutableArray *newDateArray = [[NSMutableArray alloc] init];
                    
                    int indexes[100];
                    for(int i = 0; i < segCount; i++)
                        indexes[i] = 0;
                    
                    while (YES) {
                        BOOL isBreak = YES;
                        for (int i = 0; i < segCount; i++) {
                            if (indexes[i] < countPicks[i])
                            {
                                isBreak = NO;
                                break;
                            }
                        }
                        
                        if (isBreak)
                            break;
                        
                        
                        ALAsset *asset = [array objectAtIndex:arrayPicks[0] + indexes[0]];
                        //NSDate *minDate = [asset valueForProperty:ALAssetPropertyDate];
                        NSDate *minDate = [arrayDates objectAtIndex:arrayPicks[0] + indexes[0]];
                        int selectedSeg = 0;
                        for (int i = 0; i < segCount; i++) {
                            if (indexes[i] < countPicks[i])
                            {
                                asset = [array objectAtIndex:arrayPicks[i] + indexes[i]];
                                //minDate = [asset valueForProperty:ALAssetPropertyDate];
                                minDate = [arrayDates objectAtIndex:arrayPicks[i] + indexes[i]];
                                selectedSeg = i;
                                break;
                            }
                        }
                        
                        for (int i = selectedSeg + 1; i < segCount; i++) {
                            if (indexes[i] < countPicks[i])
                            {
                                ALAsset *a = [array objectAtIndex:arrayPicks[i] + indexes[i]];
                                //NSDate *date = [a valueForProperty:ALAssetPropertyDate];
                                NSDate *date = [arrayDates objectAtIndex:arrayPicks[i] + indexes[i]];
                                if ([date compare:minDate] == NSOrderedAscending)
                                {
                                    minDate = date;
                                    asset = a;
                                    selectedSeg = i;
                                }
                            }
                        }
                        
                        [newArray addObject:asset];
                        [newDateArray addObject:minDate];
                        indexes[selectedSeg]++;
                    }
                    
                    resultArray = newArray;
                    resultDateArray = newDateArray;
                }
                
                NSMutableArray *removeObjects = [[NSMutableArray alloc] init];
                
                for (int i = 1; i < resultArray.count; i++) {
                    //ALAsset *prevAsset = [resultArray objectAtIndex:i - 1];
                    ALAsset *asset = [resultArray objectAtIndex:i];
                    
                    NSDate *prevDate = [resultDateArray objectAtIndex:i - 1];
                    NSDate *date = [resultDateArray objectAtIndex:i];
                    
                    //if ([asset isEqual:prevAsset])
                    if ([prevDate compare:date] == NSOrderedSame)
                    {
                        [removeObjects addObject:asset];
                    }
                }
                
                
                
                int i = 0;

                    for (ALAsset *asset in resultArray) {
                        BOOL isAdd = YES;
                        for (ALAsset *removeasset in removeObjects) {
                            if([removeasset isEqual:asset])
                            {
                                isAdd = NO;
                                break;
                            }
                        }
                        if (!isAdd)
                            continue;
                        CTAsset *ctasset = [[CTAsset alloc] init];
                        ctasset.asset = asset;
                        ctasset.index = i;
                        [self.assets addObject:ctasset];
                        i++;
                    }
                
            }
            else
            {
                int i = 0;
                for (NSMutableArray *assets in array) {
                    for (ALAsset *asset in assets) {
                        CTAsset *ctasset = [[CTAsset alloc] init];
                        ctasset.asset = asset;
                        ctasset.index = i;
                        [self.assets addObject:ctasset];
                        i++;
                    }
                }
            }
            
            
            [self setupPhotos];
            
            self.isLoading = NO;
            
            if (block)
                block();
        }
    };
    
    // add whole photos
    ALAssetsGroupEnumerationResultsBlock wholeBlock = ^(ALAsset *asset, NSUInteger index, BOOL *stop)
    {
        if (asset)
        {
            //NSURL *url = [asset valueForProperty:ALAssetPropertyAssetURL];
            //NSString *strUrl = [NSString stringWithFormat:@"%@", url.absoluteString];
            //NSMutableArray *assets = [array objectAtIndex:group_index];
            [array addObject:asset];
            [arrayDates addObject:[asset valueForProperty:ALAssetPropertyDate]];
        }
    };

    
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
    
    [self.picker.assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupAll
                                             usingBlock:assetGroupEnumerator
                                           failureBlock:^(NSError *error) {NSLog(@"There is an error");}];
#endif
}

- (void)setupAssets
{
    return;
/*
    self.assets = [[NSMutableArray alloc] init];

    if (self.viewType == CTAssetsViewTypeNormal)
    {
        [self setupAssetsForAlbum:self.assetsGroup withCompletion:^(){
            [self reloadData];
        }];
    }
    else if (self.viewType == CTAssetsViewTypeFiltered)
    {
        [self setupSelectedAssetsWithCompletion:^(){
            [self reloadData];
        }];
    }
    else if (self.viewType == CTAssetsViewTypeBookmarks)
    {
        //[SVProgressHUD showWithStatus:@"Loading"];
        [self setupWholeAssetsWithCompletion:^(){
            [self reloadData];
            //[SVProgressHUD dismiss];
        }];
    }
 */
}

#pragma mark - Collection View Layout

- (UICollectionViewFlowLayout *)collectionViewFlowLayoutOfOrientation:(UIInterfaceOrientation)orientation
{
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.itemSize             = kThumbnailSize;
    layout.footerReferenceSize  = CGSizeMake(0, 44.0);
    
    if (UIInterfaceOrientationIsLandscape(orientation) && (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad))
    {
        layout.sectionInset            = UIEdgeInsetsMake(9.0, 2.0, 0, 2.0);
        layout.minimumInteritemSpacing = 3.0;
        layout.minimumLineSpacing      = 3.0;
    }
    else
    {
        layout.sectionInset            = UIEdgeInsetsMake(9.0, 0, 0, 0);
        layout.minimumInteritemSpacing = 2.0;
        layout.minimumLineSpacing      = 2.0;
    }
    
    return layout;
}


#pragma mark - Notifications

- (void)addNotificationObserver
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    
    [center addObserver:self
               selector:@selector(assetsLibraryChanged:)
                   name:ALAssetsLibraryChangedNotification
                 object:nil];
    
    [center addObserver:self
               selector:@selector(selectedAssetsChanged:)
                   name:CTAssetsPickerSelectedAssetsChangedNotification
                 object:nil];
}

- (void)removeNotificationObserver
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - Assets Library Changed

- (void)assetsLibraryChanged:(NSNotification *)notification
{
    // Reload all assets
    if (notification.userInfo == nil)
        [self performSelectorOnMainThread:@selector(setupAssets) withObject:nil waitUntilDone:NO];
    
    // Reload effected assets groups
    if (notification.userInfo.count > 0)
        [self reloadAssetsGroupForUserInfo:notification.userInfo];
}


#pragma mark - Reload Assets Group

- (void)reloadAssetsGroupForUserInfo:(NSDictionary *)userInfo
{
    NSSet *URLs = [userInfo objectForKey:ALAssetLibraryUpdatedAssetGroupsKey];
    NSURL *URL  = [self.assetsGroup valueForProperty:ALAssetsGroupPropertyURL];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF == %@", URL];
    NSArray *matchedGroups = [URLs.allObjects filteredArrayUsingPredicate:predicate];
    
    // Reload assets if current assets group is updated
    if (matchedGroups.count > 0)
        [self performSelectorOnMainThread:@selector(setupAssets) withObject:nil waitUntilDone:NO];
}



#pragma mark - Selected Assets Changed

- (void)selectedAssetsChanged:(NSNotification *)notification
{
    NSArray *selectedAssets = (NSArray *)notification.object;
    
    [[self.toolbarItems objectAtIndex:1] setTitle:[self.picker toolbarTitle]];
    
    [self.picker setToolbarHidden:(selectedAssets.count == 0) animated:YES];
}


#pragma mark - Reload Data

- (void)reloadData
{
    if (self.assets.count > 0)
    {
        [self.collectionView reloadData];
        
        if (self.viewType == CTAssetsViewTypeNormal)
        {
            // goto previous album
            NSURL *groupUrl = [self.assetsGroup valueForProperty:ALAssetsGroupPropertyURL];
            NSString *strGroupUrl = [NSString stringWithFormat:@"%@", [groupUrl absoluteString]];
            
            NSString *previousUrl = [self.picker.previousAssets objectForKey:strGroupUrl];
            if (previousUrl != nil && ![previousUrl isEqualToString:@""])
            {
                [self.picker.assetsLibrary assetForURL:[NSURL URLWithString:previousUrl] resultBlock:^(ALAsset *asset) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (asset != nil)
                        {
                            NSUInteger index = [self.assets indexOfObject:asset];
                            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:0];
                            [self scrollToIndexPath:indexPath animated:NO];
                        }
                    });
                } failureBlock:^(NSError *error) {
                }];
            }
            else
            {
                //if (CGPointEqualToPoint(self.collectionView.contentOffset, CGPointZero))
                    [self.collectionView setContentOffset:CGPointMake(0, self.collectionViewLayout.collectionViewContentSize.height)];
            }

        }
        else
        {
            //if (CGPointEqualToPoint(self.collectionView.contentOffset, CGPointZero))
            {
                [self.collectionView setContentOffset:CGPointMake(0, self.collectionViewLayout.collectionViewContentSize.height)];
            }
        }
        
#if true
        self.photos = [NSMutableArray arrayWithCapacity:self.assets.count];
        // 1.create photo datas
        for (int i = 0; i < self.assets.count; i++) {
            // 替换为中等尺寸图片
            MJPhoto *photo = [[MJPhoto alloc] init];
            CTAsset *ctasset = [self.assets objectAtIndex:i];
            photo.ctasset = ctasset;
            [self.photos addObject:photo];
            
            NSIndexPath *path = [NSIndexPath indexPathForItem:i inSection:0];
            UICollectionViewCell *theCell = [self.collectionView cellForItemAtIndexPath:path];
            photo.srcView = theCell;
        }
#endif
        
    }
    else
    {
        self.photos = [[NSMutableArray alloc] init];
        [self showNoAssets];
    }
}

- (void)scrollToPrevious
{
#if false
    NSURL *groupUrl = [self.assetsGroup valueForProperty:ALAssetsGroupPropertyURL];
    NSString *strGroupUrl = [NSString stringWithFormat:@"%@", [groupUrl absoluteString]];
    
    NSString *previousUrl = [self.picker.previousAssets objectForKey:strGroupUrl];
    if (previousUrl != nil && ![previousUrl isEqualToString:@""])
    {
        [self.picker.assetsLibrary assetForURL:[NSURL URLWithString:previousUrl] resultBlock:^(ALAsset *asset) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (asset != nil)
                {
                    NSUInteger index = [self.assets indexOfObject:asset];
                    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:0];
                    [self scrollToIndexPath:indexPath animated:NO];
                }
            });
        } failureBlock:^(NSError *error) {
        }];
    }
    else
    {
        if (CGPointEqualToPoint(self.collectionView.contentOffset, CGPointZero))
        {
            CGPoint bottomOffset = CGPointMake(0, self.collectionViewLayout.collectionViewContentSize.height);
        
            [self.collectionView setContentOffset:bottomOffset];
        }
    }
#else
    
    if (self.previousAsset)
    {
        NSUInteger index = self.previousAsset.index;
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:0];
        [self scrollToIndexPath:indexPath animated:NO];
    }
    else
    {
        if (CGPointEqualToPoint(self.collectionView.contentOffset, CGPointZero))
        {
            CGPoint bottomOffset = CGPointMake(0, self.collectionViewLayout.collectionViewContentSize.height);
            
            [self.collectionView setContentOffset:bottomOffset];
        }
    }
    
#endif
}

- (CGPoint)pointForIndexPath:(NSIndexPath *)indexPath
{
    
    CGPoint pt = CGPointZero;
    
    UICollectionViewLayoutAttributes *attributes = [self.collectionView layoutAttributesForItemAtIndexPath:indexPath];
    if (attributes)
    {
        CGRect rt = attributes.frame;
        pt = CGPointMake(0, rt.origin.y);
        
        UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)self.collectionViewLayout;
        //pt.x += layout.sectionInset.left;
        
        // top edge
        pt.y -= layout.sectionInset.top;
        
        // status bar height
        pt.y -= [UIApplication sharedApplication].statusBarFrame.size.height;
        
        // navigation bar height
        if (self.navigationController.navigationBar.translucent == YES)
        {
            pt.y -= self.navigationController.navigationBar.frame.size.height;
        }
        
        return pt;
        
        
    }
    return pt;
}

- (void)scrollToIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated
{
    //[self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionTop animated:NO];
    
    CGPoint cur = [self.collectionView contentOffset];
    
    if (indexPath == nil)
        return;
    
    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)self.collectionViewLayout;
    int index = indexPath.row;
    CGPoint pt = [self pointForIndexPath:indexPath];
    
    if (self.collectionViewLayout.collectionViewContentSize.height < self.collectionView.bounds.size.height)
        return;
    
    
    CGPoint bottomOffset = CGPointMake(0, self.collectionView.contentSize.height - self.collectionView.bounds.size.height);
    
    if (pt.y > bottomOffset.y)
        [self.collectionView setContentOffset:bottomOffset animated:animated];
    else
        [self.collectionView setContentOffset:CGPointMake(0, pt.y) animated:animated];
}

- (CGPoint)pointForUpperLeftItem
{
    CGPoint pt = self.collectionView.contentOffset;
    
    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)self.collectionViewLayout;
    pt.x += layout.sectionInset.left;
    
    // top edge
    pt.y += layout.sectionInset.top;
    
    // status bar height
    pt.y += [UIApplication sharedApplication].statusBarFrame.size.height;
    
    // navigation bar height
    if (self.navigationController.navigationBar.translucent == YES)
    {
        pt.y += self.navigationController.navigationBar.frame.size.height;
    }

    return pt;
}

- (NSIndexPath *)indexPathForUpperLeftItem
{
    NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:[self pointForUpperLeftItem]];
    return indexPath;
}

- (NSComparisonResult)compareDatesWithDate:(NSDate *)a b:(NSDate *)b
{
    NSUInteger dateFlags = NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit;
    NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *selfComponents = [gregorianCalendar components:dateFlags fromDate:a];
    NSDate *selfDateOnly = [gregorianCalendar dateFromComponents:selfComponents];
    
    NSDateComponents *otherCompents = [gregorianCalendar components:dateFlags fromDate:b];
    NSDate *otherDateOnly = [gregorianCalendar dateFromComponents:otherCompents];
    return [selfDateOnly compare:otherDateOnly];
}

#pragma mark - No assets

- (void)showNoAssets
{
    self.collectionView.backgroundView = [self.picker noAssetsView];
}


#pragma mark - Collection View Data Source

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.assets.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CTAssetsViewCell *cell =
    [collectionView dequeueReusableCellWithReuseIdentifier:CTAssetsViewCellIdentifier
                                              forIndexPath:indexPath];
    
    //ALAsset *asset = [self.assets objectAtIndex:indexPath.row];
    CTAsset *ctasset = [self.assets objectAtIndex:indexPath.row];
    ALAsset *asset = ((CTAsset *)[self.assets objectAtIndex:indexPath.row]).asset;
    
    if ([self.picker.delegate respondsToSelector:@selector(assetsPickerController:shouldEnableAsset:)])
        cell.enabled = [self.picker.delegate assetsPickerController:self.picker shouldEnableAsset:asset];
    else
        cell.enabled = YES;
    
    MJPhoto *photo = [self.photos objectAtIndex:indexPath.row];

    BOOL isOverlay = NO;
    // Overlay feature
    for (NSString *overlayName in [self.picker.overlayAssets allKeys]) {
        NSArray *assets = [self.picker.overlayAssets objectForKey:overlayName];
        if ([assets containsObject:asset])
        {
            cell.overlayName = overlayName;
            photo.overlayName = overlayName;
            isOverlay = YES;
        }
    }
    
    if (isOverlay == NO)
    {
        cell.overlayName = nil;
        photo.overlayName = nil;
    }
    
    // XXX
    // Setting `selected` property blocks further deselection.
    // Have to call selectItemAtIndexPath too. ( ref: http://stackoverflow.com/a/17812116/1648333 )
    if ([self.picker.selectedAssets containsObject:asset])
    {
        cell.selected = YES;
        [collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
        
        photo.selected = YES;
    }
    else
    {
        cell.selected = NO;
        [collectionView deselectItemAtIndexPath:indexPath animated:NO];
        photo.selected = NO;
    }
    
    [cell bind:ctasset];

    photo.srcView = cell;
    
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    CTAssetsSupplementaryView *view =
    [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter
                                       withReuseIdentifier:CTAssetsSupplementaryViewIdentifier
                                              forIndexPath:indexPath];
    
    [view bind:self.assets isLoading:self.isLoading];
    
    return view;
}


#pragma mark - Collection View Delegate

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    //ALAsset *asset = [self.assets objectAtIndex:indexPath.row];
    ALAsset *asset = ((CTAsset*)[self.assets objectAtIndex:indexPath.row]).asset;
    
    CTAssetsViewCell *cell = (CTAssetsViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    
    if (!cell.isEnabled)
        return NO;
    else if ([self.picker.delegate respondsToSelector:@selector(assetsPickerController:shouldSelectAsset:)])
        return [self.picker.delegate assetsPickerController:self.picker shouldSelectAsset:asset];
    else
        return YES;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    //ALAsset *asset = [self.assets objectAtIndex:indexPath.row];
    ALAsset *asset = ((CTAsset *)[self.assets objectAtIndex:indexPath.row]).asset;
    
    [self.picker selectAsset:asset];
    
    if ([self.picker.delegate respondsToSelector:@selector(assetsPickerController:didSelectAsset:)])
        [self.picker.delegate assetsPickerController:self.picker didSelectAsset:asset];
    
    MJPhoto *photo = [self.photos objectAtIndex:indexPath.row];
    photo.selected = YES;
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    //ALAsset *asset = [self.assets objectAtIndex:indexPath.row];
    ALAsset *asset = ((CTAsset *)[self.assets objectAtIndex:indexPath.row]).asset;
    
    if ([self.picker.delegate respondsToSelector:@selector(assetsPickerController:shouldDeselectAsset:)])
        return [self.picker.delegate assetsPickerController:self.picker shouldDeselectAsset:asset];
    else
        return YES;
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    //ALAsset *asset = [self.assets objectAtIndex:indexPath.row];
    ALAsset *asset = ((CTAsset *)[self.assets objectAtIndex:indexPath.row]).asset;
    
    [self.picker deselectAsset:asset];
    
    if ([self.picker.delegate respondsToSelector:@selector(assetsPickerController:didDeselectAsset:)])
        [self.picker.delegate assetsPickerController:self.picker didDeselectAsset:asset];
    
    MJPhoto *photo = [self.photos objectAtIndex:indexPath.row];
    photo.selected = NO;
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
    //ALAsset *asset = [self.assets objectAtIndex:indexPath.row];
    ALAsset *asset = ((CTAsset *)[self.assets objectAtIndex:indexPath.row]).asset;
    
    if ([self.picker.delegate respondsToSelector:@selector(assetsPickerController:shouldHighlightAsset:)])
        return [self.picker.delegate assetsPickerController:self.picker shouldHighlightAsset:asset];
    else
        return YES;
}

- (void)collectionView:(UICollectionView *)collectionView didHighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
    //ALAsset *asset = [self.assets objectAtIndex:indexPath.row];
    ALAsset *asset = ((CTAsset *)[self.assets objectAtIndex:indexPath.row]).asset;
    
    if ([self.picker.delegate respondsToSelector:@selector(assetsPickerController:didHighlightAsset:)])
        [self.picker.delegate assetsPickerController:self.picker didHighlightAsset:asset];
}

- (void)collectionView:(UICollectionView *)collectionView didUnhighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
    //ALAsset *asset = [self.assets objectAtIndex:indexPath.row];
    ALAsset *asset = ((CTAsset *)[self.assets objectAtIndex:indexPath.row]).asset;
    
    if ([self.picker.delegate respondsToSelector:@selector(assetsPickerController:didUnhighlightAsset:)])
        [self.picker.delegate assetsPickerController:self.picker didUnhighlightAsset:asset];
}

#pragma mark - Long Press Gesture Handler
-(void)handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer
{
    //if (gestureRecognizer.state != UIGestureRecognizerStateEnded) {
    //    return;
    //}
    CGPoint p = [gestureRecognizer locationInView:self.collectionView];
    
    NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:p];
    if (indexPath == nil){
        NSLog(@"couldn't find index path");
    } else {
        if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
            NSLog(@"UIGestureRecognizerStateEnded");
            //Do Whatever You want on End of Gesture
        }
        else if (gestureRecognizer.state == UIGestureRecognizerStateBegan){
            NSLog(@"UIGestureRecognizerStateBegan.");
            //Do Whatever You want on Began of Gesture
            // get the cell at indexPath (the one you long pressed)
//            UICollectionViewCell* cell = [self.collectionView cellForItemAtIndexPath:indexPath];
            // do stuff with the cell
            
//            int count = self.assets.count;
            
            // 2.显示相册
            MJPhotoBrowser *browser = [[MJPhotoBrowser alloc] init];
            browser.assetsViewControllerDelegate = self;
            browser.currentPhotoIndex = indexPath.row; // 弹出相册时显示的第一张图片是？
            browser.photos = self.photos; // 设置所有的图片
            [browser show:nil];
        }
        
    }
}

- (void)tapAsset:(CTAsset *)ctasset
{
    //return;
    
    NSUInteger index = ctasset.index;
    if (index > self.assets.count)
    {
        NSLog(@"tapAsset: Index over");
        return;
    }
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:0];

    if ([[self.collectionView cellForItemAtIndexPath:indexPath] isSelected])
    {
        [self.collectionView deselectItemAtIndexPath:indexPath animated:NO];
        [self collectionView:self.collectionView didDeselectItemAtIndexPath:indexPath];
    }
    else
    {
        [self.collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
        [self collectionView:self.collectionView didSelectItemAtIndexPath:indexPath];
    }
}

#pragma mark -Floating tray delegate
- (void)floatingTrayNext
{
    NSIndexPath *indexPath = [self indexPathForUpperLeftItem];
    if (indexPath == nil)
        return;
    
    // get date of upper-left corner item.
    CTAssetsViewCell *cell = (CTAssetsViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
    //ALAsset *asset = cell.asset;
    CTAsset *ctasset = cell.ctasset;
    CGFloat topY = [self pointForIndexPath:indexPath].y;
    NSIndexPath *nextIndexPath = indexPath;
    while (YES) {
        nextIndexPath = [NSIndexPath indexPathForItem:nextIndexPath.row + 1 inSection:0];
        if (nextIndexPath.row >= [self.assets count])
            break;
        
        cell = (CTAssetsViewCell *)[self.collectionView cellForItemAtIndexPath:nextIndexPath];
        //asset = cell.asset;
        ctasset = cell.ctasset;
        
        if (topY < [self pointForIndexPath:nextIndexPath].y)
            break;
    }
    NSUInteger index = ctasset.index;
    NSDate *assetDate = [ctasset.asset valueForProperty:ALAssetPropertyDate];
    
    if ([self.picker.previousDates count] <= 0)
        return;
    
    NSDate *nextDate = nil;
    for (NSDate *date in self.picker.previousDates) {
        if ([self compareDatesWithDate:assetDate b:date] == NSOrderedAscending)
        {
            nextDate = [[NSDate alloc] initWithTimeIntervalSince1970:[date timeIntervalSince1970]];
            break;
        }
    }
    
    BOOL isScrolled = NO;
    
    if (nextDate != nil)
    {
        for (NSUInteger i = index; i < [self.assets count]; i++)
        {
            ctasset = [self.assets objectAtIndex:i];
            assetDate = [ctasset.asset valueForProperty:ALAssetPropertyDate];
            
            NSIndexPath *newIndexPath = [NSIndexPath indexPathForItem:i inSection:0];
            
            if (([self compareDatesWithDate:nextDate b:assetDate] == NSOrderedSame ||
                 [self compareDatesWithDate:nextDate b:assetDate] == NSOrderedAscending) && [self pointForIndexPath:indexPath].y < [self pointForIndexPath:newIndexPath].y)
            {
                [self scrollToIndexPath:newIndexPath animated:YES];
                isScrolled = YES;
                break;
            }
        }
    }
    
    if (!isScrolled)
    {
        CGPoint bottomOffset = CGPointMake(0, self.collectionView.contentSize.height - self.collectionView.bounds.size.height);
        
        [self.collectionView setContentOffset:bottomOffset animated:YES];
    }
    
}

- (void)floatingTrayPrev
{
    

    NSIndexPath *indexPath = [self indexPathForUpperLeftItem];
    if (indexPath == nil)
        return;
    
    // get date of upper-left corner item.
    CTAssetsViewCell *cell = (CTAssetsViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
    CTAsset *ctasset = cell.ctasset;
    NSUInteger index = ctasset.index;
    NSDate *assetDate = [ctasset.asset valueForProperty:ALAssetPropertyDate];
    
    if ([self.picker.previousDates count] <= 0)
        return;
    
    NSDate *prevDate = nil;
    for (int i = [self.picker.previousDates count] - 1; i >= 0; i--) {
        NSDate *date = [self.picker.previousDates objectAtIndex:i];
        if ([self compareDatesWithDate:assetDate b:date] == NSOrderedDescending ||
            [self compareDatesWithDate:assetDate b:date] == NSOrderedSame)
        {
            prevDate = date;
            break;
        }
    }
    
    if (prevDate == nil)
    {
        NSIndexPath *newIndexPath = [NSIndexPath indexPathForItem:0 inSection:0];
        [self scrollToIndexPath:newIndexPath animated:YES];
        return;
    }
    
    BOOL isScrolled = NO;
    
    for (int i = index; i >= 0; i--)
    {
        ctasset = [self.assets objectAtIndex:i];
        assetDate = [ctasset.asset valueForProperty:ALAssetPropertyDate];
        
        NSIndexPath *newIndexPath = [NSIndexPath indexPathForItem:i inSection:0];
        CGFloat y = [self pointForIndexPath:indexPath].y;
        CGFloat newY = [self pointForIndexPath:newIndexPath].y;
        
        if (([self compareDatesWithDate:prevDate b:assetDate] == NSOrderedSame ||
             [self compareDatesWithDate:prevDate b:assetDate] == NSOrderedDescending) && y > newY)
        {
            CTAsset *prevAsset = ctasset;
            int prevI = i;
            while (YES) {
                
                ctasset = prevAsset;
                i = prevI;
                
                prevI--;
                if (prevI < 0)
                    break;
                
                prevAsset = [self.assets objectAtIndex:prevI];
                NSDate *prevDate = [prevAsset.asset valueForProperty:ALAssetPropertyDate];
                if ([self compareDatesWithDate:assetDate b:prevDate] == NSOrderedSame)
                {
                    //
                }
                else
                    break;
            }
            newIndexPath = [NSIndexPath indexPathForItem:i inSection:0];
            isScrolled = YES;
            [self scrollToIndexPath:newIndexPath animated:YES];
            break;
        }
    }
    
    if (isScrolled == NO)
        [self scrollToIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] animated:YES];

}

@end