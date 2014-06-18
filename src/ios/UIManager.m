//
//  UIManager.m
//  TestPlugin
//
//  Created by Donald Pae on 5/12/14.
//
//

#import "UIManager.h"

static UIManager *_sharedManager = nil;

@implementation UIManager

+ (UIManager *)sharedManager
{
    if (_sharedManager == nil) {
        _sharedManager = [[UIManager alloc] init];
    }
    return _sharedManager;
}

- (id)init
{
    self = [super init];
    if (self) {
        
        self.titleFont       = [UIFont systemFontOfSize:12];
        self.titleHeight     = 20.0f;
        self.videoIcon       = [UIImage imageNamed:@"CTAssetsPickerVideo"];
        self.titleColor      = [UIColor whiteColor];
        self.checkedIcon     = [UIImage imageNamed:@"CTAssetsPickerChecked"];
        self.selectedColor   = [UIColor colorWithWhite:1 alpha:0.3];
        self.disabledColor   = [UIColor colorWithWhite:1 alpha:0.9];
        
        // overlay icons
        self.overlayIcons     = [[NSMutableDictionary alloc] init];
        
        // set default overlay icon
        [self.overlayIcons setObject:[UIImage imageNamed:@"CTAssetsPickerOverlay"] forKey:kDefaultOverlayIconKey];
        
        self.overlayColor    = [UIColor colorWithWhite:1 alpha:0.3];
        
        self.emptyImage      = [UIImage imageNamed:@"CTAssetsPickerEmpty"];
        
        self.uncheckedIcon   = [UIImage imageNamed:@"CTAssetsPickerUnchecked"];
        
        self.thumbnailIcon   = [UIImage imageNamed:@"CTAssetsPickerThumbnail"];
    }
    return self;

}

- (UIImage *)overlayIconForKey:(NSString *)key
{
    UIImage *icon = [self.overlayIcons objectForKey:key];
    
    if (icon == nil)
        icon = [self.overlayIcons objectForKey:kDefaultOverlayIconKey];
    
    return icon;
}

@end
