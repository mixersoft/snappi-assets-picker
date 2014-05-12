//
//  UIManager.h
//  TestPlugin
//
//  Created by Donald Pae on 5/12/14.
//
//

#import <Foundation/Foundation.h>

@interface UIManager : NSObject

@property (nonatomic, strong) UIFont *titleFont;
@property (nonatomic) CGFloat titleHeight;
@property (nonatomic, strong) UIImage *videoIcon;
@property (nonatomic, strong) UIColor *titleColor;
@property (nonatomic, strong) UIImage *checkedIcon;
@property (nonatomic, strong) UIColor *selectedColor;
@property (nonatomic, strong) UIColor *disabledColor;
@property (nonatomic, strong) UIImage *overlayIcon;
@property (nonatomic, strong) UIColor *overlayColor;
@property (nonatomic, strong) UIImage *emptyImage;
@property (nonatomic, strong) UIImage *uncheckedIcon;
@property (nonatomic, strong) UIImage *thumbnailIcon;

+ (UIManager *)sharedManager;

@end
