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



NSString * const CTAssetsViewCellIdentifier = @"CTAssetsViewCellIdentifier";
NSString * const CTAssetsSupplementaryViewIdentifier = @"CTAssetsSupplementaryViewIdentifier";


@interface CTAssetsPickerController()

@property (nonatomic, strong) UIBarButtonItem *titleButton;
@property (nonatomic, strong) ALAssetsLibrary *assetsLibrary;

- (void)finishPickingAssets:(id)sender;
- (void)setActionForTitleButton:(BOOL)bSet;

- (NSString *)toolbarTitle;
- (UIView *)noAssetsView;

@end



@interface CTAssetsViewController () <FloatingTrayDelegate>

@property (nonatomic, weak) CTAssetsPickerController *picker;
@property (nonatomic, strong) NSMutableArray *assets;
@property (nonatomic, strong) NSMutableArray *photos;

@property (nonatomic, strong) FloatingTrayView* floatingTrayView;

@end


@implementation CTAssetsViewController


- (id)initWithType:(CTAssetsViewType)type
{
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

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self setupButtons];
    [self setupToolbar];
    [self setupAssets];
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
                int index = indexPath.row;
                CTAssetsViewCell *cell = (CTAssetsViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
                
                ALAsset *asset = cell.asset;
                url = [asset valueForProperty:ALAssetPropertyAssetURL];
                NSString *strAssetsUrl = [NSString stringWithFormat:@"%@", [url absoluteString]];
                
                [self.picker.previousAssets setObject:strAssetsUrl forKey:strUrl];
            }
            else
                [self.picker.previousAssets removeObjectForKey:strUrl];
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

- (CTAssetsPickerController *)picker
{
    return (CTAssetsPickerController *)self.navigationController;
}


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

- (void)setupAssets
{
    
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

    
    if (!self.assets)
        self.assets = [[NSMutableArray alloc] init];
    else
        [self.assets removeAllObjects];
        
    
    // add whole photos
    ALAssetsGroupEnumerationResultsBlock resultsBlock = ^(ALAsset *asset, NSUInteger index, BOOL *stop)
    {
        if (asset && ![self.assets containsObject:asset])
        {
            [self.assets addObject:asset];
        }
        else
            [self reloadData];
    };
    
    // add selected photos
    ALAssetsGroupEnumerationResultsBlock selectResultBlock = ^(ALAsset *asset, NSUInteger index, BOOL *stop)
    {
        if (asset)
        {
            if( [self.picker.selectedAssets containsObject:asset] )
            {
                if (![self.assets containsObject:asset])
                    [self.assets addObject:asset];
            }
        }
    };
    
    switch (self.viewType) {
        case CTAssetsViewTypeNormal:
            [self.assetsGroup enumerateAssetsUsingBlock:resultsBlock];
            break;
            
        case CTAssetsViewTypeFiltered:
        {
            NSMutableArray *assetGroups = [[NSMutableArray alloc] init];
            
            void (^ assetGroupEnumerator) ( ALAssetsGroup *, BOOL *)= ^(ALAssetsGroup *group, BOOL *stop) {
                if(group != nil) {
                    [group enumerateAssetsUsingBlock:selectResultBlock];
                    [assetGroups addObject:group];
                }
                else
                    [self reloadData];
            };
            
            assetGroups = [[NSMutableArray alloc] init];
            
            [self.picker.assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupAll
                                                     usingBlock:assetGroupEnumerator
                                                   failureBlock:^(NSError *error) {NSLog(@"There is an error");}];
        }
            break;
            
        case CTAssetsViewTypeBookmarks:
        {
            NSMutableArray *assetGroups = [[NSMutableArray alloc] init];
            
            void (^ assetGroupEnumerator) ( ALAssetsGroup *, BOOL *)= ^(ALAssetsGroup *group, BOOL *stop) {
                if(group != nil) {
                    [group enumerateAssetsUsingBlock:resultsBlock];
                    [assetGroups addObject:group];
                }
            };
            
            assetGroups = [[NSMutableArray alloc] init];
            
            [self.picker.assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupAll
                                                     usingBlock:assetGroupEnumerator
                                                   failureBlock:^(NSError *error) {NSLog(@"There is an error");}];
        }
            break;
            
        default:
            break;
    }

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
        if (self.viewType == CTAssetsViewTypeBookmarks)
        {
            NSArray *sortedArray = [self.assets sortedArrayUsingComparator:^NSComparisonResult(id a, id b)
            {
                ALAsset *assetA = (ALAsset *)a;
                ALAsset *other = (ALAsset *)b;
                NSComparisonResult ret = [[assetA valueForProperty:ALAssetPropertyDate] compare:[other valueForProperty:ALAssetPropertyDate]];
                return ret;
            }];
            
            self.assets = [[NSMutableArray alloc] initWithArray:sortedArray];
        }
        
        [self.collectionView reloadData];
        
        
        
        if (self.viewType == CTAssetsViewTypeNormal)
        {

            NSURL *groupUrl = [self.assetsGroup valueForProperty:ALAssetsGroupPropertyURL];
            NSString *strGroupUrl = [NSString stringWithFormat:@"%@", [groupUrl absoluteString]];
            
            NSString *previousUrl = [self.picker.previousAssets objectForKey:strGroupUrl];
            if (previousUrl != nil || ![previousUrl isEqualToString:@""])
            {
                [self.picker.assetsLibrary assetForURL:[NSURL URLWithString:previousUrl] resultBlock:^(ALAsset *asset) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSUInteger index = [self.assets indexOfObject:asset];
                        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:0];
                        [self scrollToIndexPath:indexPath animated:NO];
                    });
                } failureBlock:^(NSError *error) {
                }];
            }
            else
            {
                if (CGPointEqualToPoint(self.collectionView.contentOffset, CGPointZero))
                    [self.collectionView setContentOffset:CGPointMake(0, self.collectionViewLayout.collectionViewContentSize.height)];
            }

        }
        else
        {
            if (CGPointEqualToPoint(self.collectionView.contentOffset, CGPointZero))
                [self.collectionView setContentOffset:CGPointMake(0, self.collectionViewLayout.collectionViewContentSize.height)];
        }
        
        
        self.photos = [NSMutableArray arrayWithCapacity:self.assets.count];
        // 1.create photo datas
        for (int i = 0; i < self.assets.count; i++) {
            // 替换为中等尺寸图片
            MJPhoto *photo = [[MJPhoto alloc] init];
            photo.asset = [self.assets objectAtIndex:i];
            [self.photos addObject:photo];
            
            NSIndexPath *path = [NSIndexPath indexPathForItem:i inSection:0];
            UICollectionViewCell *theCell = [self.collectionView cellForItemAtIndexPath:path];
            photo.srcView = theCell;
        }
    }
    else
    {
        self.photos = [[NSMutableArray alloc] init];
        [self showNoAssets];
    }
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
    
    CGPoint pt = [self pointForIndexPath:indexPath];
    
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
    
    ALAsset *asset = [self.assets objectAtIndex:indexPath.row];
    
    if ([self.picker.delegate respondsToSelector:@selector(assetsPickerController:shouldEnableAsset:)])
        cell.enabled = [self.picker.delegate assetsPickerController:self.picker shouldEnableAsset:asset];
    else
        cell.enabled = YES;
    
    MJPhoto *photo = [self.photos objectAtIndex:indexPath.row];
    
    // Overlay feature
    if ([self.picker.overlayAssets containsObject:asset])
    {
        cell.overlay = YES;
        photo.overlay = YES;
    }
    else
    {
        cell.overlay = NO;
        photo.overlay = NO;
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
    
    [cell bind:asset];

    photo.srcView = cell;
    
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    CTAssetsSupplementaryView *view =
    [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter
                                       withReuseIdentifier:CTAssetsSupplementaryViewIdentifier
                                              forIndexPath:indexPath];
    
    [view bind:self.assets];
    
    return view;
}


#pragma mark - Collection View Delegate

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    ALAsset *asset = [self.assets objectAtIndex:indexPath.row];
    
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
    ALAsset *asset = [self.assets objectAtIndex:indexPath.row];
    
    [self.picker selectAsset:asset];
    
    if ([self.picker.delegate respondsToSelector:@selector(assetsPickerController:didSelectAsset:)])
        [self.picker.delegate assetsPickerController:self.picker didSelectAsset:asset];
    
    MJPhoto *photo = [self.photos objectAtIndex:indexPath.row];
    photo.selected = YES;
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    ALAsset *asset = [self.assets objectAtIndex:indexPath.row];
    
    if ([self.picker.delegate respondsToSelector:@selector(assetsPickerController:shouldDeselectAsset:)])
        return [self.picker.delegate assetsPickerController:self.picker shouldDeselectAsset:asset];
    else
        return YES;
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    ALAsset *asset = [self.assets objectAtIndex:indexPath.row];
    
    [self.picker deselectAsset:asset];
    
    if ([self.picker.delegate respondsToSelector:@selector(assetsPickerController:didDeselectAsset:)])
        [self.picker.delegate assetsPickerController:self.picker didDeselectAsset:asset];
    
    MJPhoto *photo = [self.photos objectAtIndex:indexPath.row];
    photo.selected = NO;
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
    ALAsset *asset = [self.assets objectAtIndex:indexPath.row];
    
    if ([self.picker.delegate respondsToSelector:@selector(assetsPickerController:shouldHighlightAsset:)])
        return [self.picker.delegate assetsPickerController:self.picker shouldHighlightAsset:asset];
    else
        return YES;
}

- (void)collectionView:(UICollectionView *)collectionView didHighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
    ALAsset *asset = [self.assets objectAtIndex:indexPath.row];
    
    if ([self.picker.delegate respondsToSelector:@selector(assetsPickerController:didHighlightAsset:)])
        [self.picker.delegate assetsPickerController:self.picker didHighlightAsset:asset];
}

- (void)collectionView:(UICollectionView *)collectionView didUnhighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
    ALAsset *asset = [self.assets objectAtIndex:indexPath.row];
    
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

- (void)tapAsset:(ALAsset *)asset
{
    NSUInteger index = [self.assets indexOfObject:asset];
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
    ALAsset *asset = cell.asset;
    CGFloat topY = [self pointForIndexPath:indexPath].y;
    NSIndexPath *nextIndexPath = indexPath;
    while (YES) {
        nextIndexPath = [NSIndexPath indexPathForItem:nextIndexPath.row + 1 inSection:0];
        if (nextIndexPath.row >= [self.assets count])
            break;
        
        cell = (CTAssetsViewCell *)[self.collectionView cellForItemAtIndexPath:nextIndexPath];
        asset = cell.asset;
        
        if (topY < [self pointForIndexPath:nextIndexPath].y)
            break;
    }
    NSUInteger index = [self.assets indexOfObject:asset];
    NSDate *assetDate = [asset valueForProperty:ALAssetPropertyDate];
    
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
    
    if (nextDate == nil)
        return;
    
    for (NSUInteger i = index; i < [self.assets count]; i++)
    {
        asset = [self.assets objectAtIndex:i];
        assetDate = [asset valueForProperty:ALAssetPropertyDate];
        
        NSIndexPath *newIndexPath = [NSIndexPath indexPathForItem:i inSection:0];
        
        if (([self compareDatesWithDate:nextDate b:assetDate] == NSOrderedSame ||
             [self compareDatesWithDate:nextDate b:assetDate] == NSOrderedAscending) && [self pointForIndexPath:indexPath].y < [self pointForIndexPath:newIndexPath].y)
        {
            [self scrollToIndexPath:newIndexPath animated:YES];
            break;
        }
    }
    
}

- (void)floatingTrayPrev
{
    NSIndexPath *indexPath = [self indexPathForUpperLeftItem];
    if (indexPath == nil)
        return;
    
    // get date of upper-left corner item.
    CTAssetsViewCell *cell = (CTAssetsViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
    ALAsset *asset = cell.asset;
    NSUInteger index = [self.assets indexOfObject:asset];
    NSDate *assetDate = [asset valueForProperty:ALAssetPropertyDate];
    
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
        asset = [self.assets objectAtIndex:i];
        assetDate = [asset valueForProperty:ALAssetPropertyDate];
        
        NSIndexPath *newIndexPath = [NSIndexPath indexPathForItem:i inSection:0];
        CGFloat y = [self pointForIndexPath:indexPath].y;
        CGFloat newY = [self pointForIndexPath:newIndexPath].y;
        
        if (([self compareDatesWithDate:prevDate b:assetDate] == NSOrderedSame ||
             [self compareDatesWithDate:prevDate b:assetDate] == NSOrderedDescending) && y > newY)
        {
            ALAsset *prevAsset = asset;
            int prevI = i;
            while (YES) {
                
                asset = prevAsset;
                i = prevI;
                
                prevI--;
                if (prevI < 0)
                    break;
                
                prevAsset = [self.assets objectAtIndex:prevI];
                NSDate *prevDate = [prevAsset valueForProperty:ALAssetPropertyDate];
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