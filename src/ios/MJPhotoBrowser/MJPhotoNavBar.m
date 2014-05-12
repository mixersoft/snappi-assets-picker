//
//  MJPhotoNavBar.m
//  TestPlugin
//
//  Created by Donald Pae on 5/13/14.
//
//

#import "MJPhotoNavBar.h"
#import "UIManager.h"
#import "MJPhoto.h"

#define kSideMargin     5
#define kTopmargin      15


@interface MJPhotoNavBar () {
    UIButton *_btnThumbnail;
    UIImageView *_iconView;
}

@end

@implementation MJPhotoNavBar

- (void)setCurrentPhotoIndex:(NSUInteger)currentPhotoIndex
{
    _currentPhotoIndex = currentPhotoIndex;
    MJPhoto *photo = [_photos objectAtIndex:currentPhotoIndex];
    if (photo.selected)
        _iconView.image = [UIManager sharedManager].checkedIcon;
    else if (photo.overlay)
        _iconView.image = [UIManager sharedManager].overlayIcon;
    else
        _iconView.image = [UIManager sharedManager].uncheckedIcon;
}

- (void)setPhotos:(NSArray *)photos
{
    _photos = photos;
    
    if (_photos.count > 1) {
        _iconView = [[UIImageView alloc] init];
        CGSize imageSize = [UIManager sharedManager].checkedIcon.size;
        _iconView.frame = CGRectMake(self.bounds.size.width - imageSize.width - kSideMargin, kTopmargin, imageSize.width, imageSize.height);
        _iconView.backgroundColor = [UIColor clearColor];
        [self addSubview:_iconView];
        
        _btnThumbnail = [UIButton buttonWithType:UIButtonTypeCustom];
        [_btnThumbnail setImage:[UIManager sharedManager].thumbnailIcon forState:UIControlStateNormal];
        [_btnThumbnail addTarget:self action:@selector(btnThumbnailClicked:) forControlEvents:UIControlEventTouchUpInside];
        imageSize = [UIManager sharedManager].thumbnailIcon.size;
        _btnThumbnail.frame = CGRectMake(kSideMargin, kTopmargin, imageSize.width, imageSize.height);
        [self addSubview:_btnThumbnail];
    }
}

- (void)btnThumbnailClicked:(id)sender
{
    [self.delegate gotoThumbnail];
}

@end
