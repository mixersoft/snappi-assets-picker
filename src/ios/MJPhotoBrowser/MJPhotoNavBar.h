//
//  MJPhotoNavBar.h
//  TestPlugin
//
//  Created by Donald Pae on 5/13/14.
//
//

#import <Foundation/Foundation.h>

@protocol MJPhotoNavBarDelegate <NSObject>

- (void)gotoThumbnail;

@end

@interface MJPhotoNavBar : UIView

@property (nonatomic, strong) NSArray *photos;

@property (nonatomic, assign) NSUInteger currentPhotoIndex;

@property (nonatomic, weak) id<MJPhotoNavBarDelegate> delegate;

@end
