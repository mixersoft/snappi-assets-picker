//
//  CAssetsPickerPlugin.h
//  AssetsPlugin
//
//  Created by Donald Pae on 4/22/14.
//
//

#import <Cordova/CDVPlugin.h>
#import "CTAssetsPickerController.h"

typedef enum {
    DestinationTypeDataURL = 0,
    DestinationTypeFileURI = 1
}DestinationType;

typedef enum {
    EncodingTypeJPEG = 0,
    EncodingTypePNG = 1
}EncodingType;

// return value
#define kIdKey      @"id"
#define kUuidKey    @"uuid"
#define kOrigExtKey @"orig_ext"
#define kLabelKey   @"label"
#define kDataKey    @"data"
#define kExifKey    @"exif"
#define kDateTimeOriginalKey    @"DateTimeOriginal"
#define kPixelXDimensionKey      @"PixelXDimension"
#define kPixelYDimensionKey     @"PixelYDimension"
#define kOrientationKey         @"Orientation"
#define kCorrectOrientation     @"correctOrientation"
#define kBookmarks              @"bookmarks"
#define kBookmarksDate          @"date"
#define kPluckKey               @"pluck"
#define kFromDateKey            @"fromDate"
#define kToDateKey              @"toDate"
#define kLastDateKey            @"lastDate"
#define kAssetsKey              @"assets"
#define kThumbnailKey           @"thumbnail"

#define DATETIME_FORMAT @"yyyy-MM-dd HH:mm:ss"
#define DATE_FORMAT @"yyyy-MM-dd"
#define DATETIME_EXIF_FORMAT    @"yyyy:MM:dd HH:mm:ss"

#define DATETIME_JSON_FORMAT @"yyyy-MM-dd'T'HH:mm:ss.SSS"

// parameter
#define kQualityKey         @"quality"
#define kDestinationTypeKey @"destinationType"
#define kEncodingTypeKey    @"encodingType"
#define kTargetWidth        @"targetWidth"
#define kTargetHeight       @"targetHeight"
#define kOverlayKey         @"overlay"
#define kPopoverOptions     @"popoverOptions"
#define kPopoverX       @"x"
#define kPopoverY       @"y"
#define kPopoverWidth   @"width"
#define kPopoverHeight  @"height"
#define kPopoverArrowDir    @"arrowDir"
#define kPopoverViewWidth       @"popoverWidth"
#define kPopoverViewHeight      @"popoverHeight"

#define kPreviousSelectedName   @"previousSelected"


@interface CAssetsPickerPlugin : CDVPlugin <UINavigationControllerDelegate, CTAssetsPickerControllerDelegate, UIPopoverControllerDelegate>

/**
 * picker
 *
 * The corresponding property is an instance of the assets picker navigation controller
 * Used to show all album groups and assets with views.
 */
@property (strong, nonatomic) CTAssetsPickerController *picker;

/**
 * lastCommand
 * 
 * The corresponding property is a command from web view to the plugin.
 */
@property (strong, nonatomic) CDVInvokedUrlCommand* latestCommand;

/**
 * hasPendingOperation
 *
 * This flag represents the plugin is processing previous command or not.
 *  When this flag is set(YES), the plugin doesn't finish previous command yet.
 */
@property (readwrite, assign) BOOL hasPendingOperation;


/**
 * popover
 *
 * Popover view controller is used to show UIs on iPad
 */
@property (nonatomic, strong) UIPopoverController *popover;


/**/////////////////////////////////////
/* Plugin interfaces
*//////////////////////////////////////
- (void)getPicture:(CDVInvokedUrlCommand *)command;
- (void)getById:(CDVInvokedUrlCommand *)command;
- (void)setOverlay:(CDVInvokedUrlCommand *)command;
- (void)getPreviousAlbums:(CDVInvokedUrlCommand *)command;
- (void)mapAssetsLibrary:(CDVInvokedUrlCommand *)command;


/************ utility functions ************/
+ (NSString *)date2str:(NSDate *)convertDate withFormat:(NSString *)formatString;
+ (UIImage *)scaleImage:(UIImage *)image scale:(CGFloat)scale;
+ (NSString *)getAppPath;
+ (NSString *)getFilePath:(NSString *)uuidString ext:(NSString *)ext;
+ (NSURL *)getUrlFromUrlString:(NSString *)urlString;
+ (NSString *)getUrlStringWithUuid:(NSString *)uuid ext:(NSString *)ext;
@end
