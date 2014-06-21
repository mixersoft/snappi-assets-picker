//
//  CAssetsPickerPlugin.m
//  AssetsPlugin
//
//  Created by Donald Pae on 4/22/14.
//
//

#import <ImageIO/CGImageSource.h>
#import <ImageIO/CGImageProperties.h>
#import "CAssetsPickerPlugin.h"
#import "URLParser.h"
#import "UIManager.h"
#import "ALAssetUtils.h"

#define EXT_JPG     @"JPG"
#define EXT_PNG     @"PNG"


@implementation CAssetsPickerPlugin {
    
    // options //////////////////////////
    int _quality;
    DestinationType _destType;
    EncodingType _encodeType;
    NSDictionary *_overlays;    // {overlayName, array of assetIds}
    NSMutableDictionary *_overlayIcons;
    NSURL *_assetURL;
    NSString *_uuid;
    int _targetWidth;
    int _targetHeight;
    BOOL _correctOrientation;
    NSMutableDictionary *_hightlightAssets;
    NSMutableArray *_highlightDates;
    BOOL _isDateBookmark;
    BOOL _isThumbnail;
    CGRect _popOverRect;
    UIPopoverArrowDirection _popOverDirection;
    ///////////////////////////////////////
}

#pragma  mark - Interfaces

- (void)getPicture:(CDVInvokedUrlCommand *)command
{
    // Set the hasPendingOperation field to prevent the webview from crashing
	self.hasPendingOperation = YES;
    
	// Save the CDVInvokedUrlCommand as a property.  We will need it later.
	self.latestCommand = command;
    
    [self initOptions];
    if ([command.arguments count]> 0)
    {
        NSDictionary *jsonData = [command.arguments objectAtIndex:0];
        [self getOptions:jsonData];
    }
    
    self.picker = [[CTAssetsPickerController alloc] init:_isDateBookmark];
    self.picker.assetsFilter         = [ALAssetsFilter allAssets];
    self.picker.showsCancelButton    = (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad);
    self.picker.delegate             = self;
    
    // previous assets/dates
    self.picker.previousAssets = [[NSMutableDictionary alloc] initWithDictionary: _hightlightAssets];
    self.picker.previousDates = [[NSMutableArray alloc] initWithArray:_highlightDates];
    
    // set selected assets
    
    if (_overlayIcons != nil)
        self.picker.prevOverlayAssetIds = [[NSMutableDictionary alloc] initWithDictionary:_overlays];
    else
        self.picker.prevOverlayAssetIds  = [[NSMutableDictionary alloc] init];
    
    // iPad
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        self.popover = [[UIPopoverController alloc] initWithContentViewController:self.picker];
        self.popover.delegate = self;
        CGRect frame = CGRectMake(0, 0, _popOverRect.origin.x, _popOverRect.origin.y);
        [self.popover presentPopoverFromRect:frame inView:self.viewController.view permittedArrowDirections:_popOverDirection animated:YES];
        [self.popover setPopoverContentSize:CGSizeMake(_popOverRect.size.width, _popOverRect.size.height) animated:NO];
        self.picker.popoverSize = _popOverRect.size;
    }
    else
    {
        [self.viewController presentViewController:self.picker animated:YES completion:nil];
    }
}

- (void)getById:(CDVInvokedUrlCommand *)command
{
    self.hasPendingOperation = YES;
    
    self.latestCommand = command;
    
    [self initOptions];
    if ([command.arguments count] > 2)
    {
        // get id or uuid
        NSString *url = [command.arguments objectAtIndex:0];
        if (url != nil)
        {
            NSURL *temp = [NSURL URLWithString:url];
            if ([temp.scheme isEqualToString:@"assets-library"]) {
                _assetURL = [NSURL URLWithString:url];
                _uuid = nil;
            }
            else {
                _assetURL = nil;
                _uuid = [NSString stringWithFormat:@"%@", url];
                
                // get orig_ext
                NSString *origExt = [command.arguments objectAtIndex:1];
                
                NSString *urlString = [NSString stringWithFormat:@"assets-library://asset/asset.%@?id=%@?ext=%@", origExt, _uuid, origExt];
                
                _assetURL = [NSURL URLWithString:urlString];
            }
        }

        // get options
        NSDictionary *jsonData = [command.arguments objectAtIndex:2];
        [self getOptions:jsonData];
        
    }
    
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    [library assetForURL:_assetURL resultBlock:^(ALAsset *asset) {
        
        // Unset the self.hasPendingOperation property
        self.hasPendingOperation = NO;
        
        CDVPluginResult *pluginResult = nil;
        NSString *resultJS = nil;
        
        if (asset == nil)
        {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"There is no corresponding asset!"];
            
            resultJS = [pluginResult toErrorCallbackString:command.callbackId];
        }
        else
        {
        
            NSDictionary *retValues = [self objectFromAsset:asset fromThumbnail:_isThumbnail];
            
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:retValues];
            resultJS = [pluginResult toSuccessCallbackString:command.callbackId];
        }
        
        [self writeJavascript:resultJS];
        
        //
    } failureBlock:^(NSError *error) {
        
        // Unset the self.hasPendingOperation property
        self.hasPendingOperation = NO;
        
        CDVPluginResult *pluginResult = nil;
        NSString *resultJS = nil;
        
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[error localizedDescription]];
        
        resultJS = [pluginResult toErrorCallbackString:command.callbackId];
        [self writeJavascript:resultJS];
        
    }];
}

- (void)setOverlay:(CDVInvokedUrlCommand *)command
{
    self.hasPendingOperation = YES;
    
    self.latestCommand = command;
    
    BOOL bRet = NO;
    NSString *msg = @"";
    if ([command.arguments count] >= 2)
    {
        // get overlay name
        NSString *overlayName = [command.arguments objectAtIndex:0];
        if (overlayName != nil)
        {
            // get overlay icon
            NSString *iconString = [command.arguments objectAtIndex:1];
            NSData *iconData = nil;
            // {overlayName, arrayOf base64 encoded icon data}
            
            iconData = [[NSData alloc] initWithBase64EncodedString:iconString options:0];
            UIImage *img = [UIImage imageWithData:iconData scale:[UIScreen mainScreen].scale];
            
            if (img == nil)
            {
                bRet = NO;
                msg = @"Incorrect image data, cannot get image from data";
            }
            else
            {
                [[UIManager sharedManager].overlayIcons setObject:img forKey:overlayName];
                
                bRet = YES;
                
                if (iconData != nil)
                    [_overlayIcons setValue:iconData forKey:overlayName];
            }
        }
        else
        {
            bRet = NO;
            msg = @"Incorrect parameters!";
        }
    }
    else
    {
        bRet = NO;
        msg = @"not enough parameters";
    }
    
    // Unset the self.hasPendingOperation property
    self.hasPendingOperation = NO;
    
    CDVPluginResult *pluginResult = nil;
    NSString *resultJS = nil;
    
    if (!bRet)
    {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:msg];
        resultJS = [pluginResult toErrorCallbackString:command.callbackId];
    }
    else
    {
        
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        resultJS = [pluginResult toSuccessCallbackString:command.callbackId];
    }
    
    [self writeJavascript:resultJS];
    
}


- (void)getPreviousAlbums:(CDVInvokedUrlCommand *)command
{
    self.hasPendingOperation = YES;
    
    self.latestCommand = command;
   
    // Unset the self.hasPendingOperation property
    self.hasPendingOperation = NO;
    
    CDVPluginResult *pluginResult = nil;
    NSString *resultJS = nil;
    
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:self.picker.previousAssets];
    resultJS = [pluginResult toSuccessCallbackString:command.callbackId];
    
    [self writeJavascript:resultJS];
    
}

- (void)mapAssetsLibrary:(CDVInvokedUrlCommand *)command
{
    self.hasPendingOperation = YES;
    self.latestCommand = command;
    
    NSArray *pluck = nil;
    NSDate *fromDate = nil;
    NSDate *toDate = nil;
    
    // parse command
    if (command.arguments.count < 1)
    {
        //
    }
    else
    {
        NSDictionary *options = [command.arguments objectAtIndex:0];
        
        pluck = [options objectForKey:kPluckKey];
       
        NSString *dateString = [options objectForKey:kFromDateKey];
        if (dateString != nil && dateString.length >= 23)
            fromDate = [CAssetsPickerPlugin str2date:[dateString substringToIndex:23] withFormat:DATETIME_JSON_FORMAT];
        
        dateString = [options objectForKey:kToDateKey];
        if (dateString != nil && dateString.length >= 23)
            toDate = [CAssetsPickerPlugin str2date:[dateString substringToIndex:23] withFormat:DATETIME_JSON_FORMAT];
    }

    
    // filtering albums

    [ALAssetUtils getAssetsWithFromDate:fromDate toDate:toDate complete:^(NSArray *arrayAssets){
        CDVPluginResult *pluginResult = nil;
        NSString *resultJS = nil;
        
        // mapped.lastDate :
        NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
        if (arrayAssets.count == 0)
        {
            if (fromDate == nil && toDate == nil)
            {
                [dic setObject:@"" forKey:kLastDateKey];
            }
            else if (fromDate != nil && toDate == nil)
            {
                [dic setObject:[CAssetsPickerPlugin date2str:fromDate withFormat:DATETIME_FORMAT] forKey:kLastDateKey];
            }
            else if (toDate != nil)
            {
                [dic setObject:[CAssetsPickerPlugin date2str:toDate withFormat:DATETIME_FORMAT] forKey:kLastDateKey];
            }
        }
        else
        {
            ALAsset *asset = [arrayAssets lastObject];
            NSDate *lastDate = [asset valueForProperty:ALAssetPropertyDate];
            [dic setObject:[CAssetsPickerPlugin date2str:lastDate withFormat:DATETIME_FORMAT] forKey:kLastDateKey];
        }
        
        // mapped.assets
        if (arrayAssets.count == 0)
        {
            [dic setObject:@"" forKey:kAssetsKey];
        }
        else
        {
            NSMutableArray *retAssets = [[NSMutableArray alloc] initWithCapacity:arrayAssets.count];
            for (ALAsset *asset in arrayAssets) {
//                NSDate *date = [asset valueForProperty:ALAssetPropertyDate];
//                CGFloat pixelXDimension = asset.defaultRepresentation.dimensions.width;
//                CGFloat pixelYDimension = asset.defaultRepresentation.dimensions.height;
                
                
                NSMutableDictionary *dicData = [[NSMutableDictionary alloc] initWithCapacity:4];
                NSMutableDictionary *exif_dict = [CAssetsPickerPlugin getExif:asset];
                
                if (pluck == nil || pluck.count == 0)
                {
                    for (NSString *key in [exif_dict allKeys]) {
                        [dicData setObject:[exif_dict objectForKey:key] forKey:key];
                    }
//                    [dicData setObject:[CAssetsPickerPlugin date2str:date withFormat:DATETIME_FORMAT] forKey:kDateTimeOriginalKey];
//                    [dicData setObject:@(pixelXDimension) forKey:kPixelXDimensionKey];
//                    [dicData setObject:@(pixelYDimension) forKey:kPixelYDimensionKey];
//                    [dicData setObject:[asset valueForProperty:ALAssetPropertyOrientation] forKey:kOrientationKey];
                }
                else
                {
                    for (NSString *key in pluck) {
                        if ([exif_dict objectForKey:key] != nil)
                            [dicData setObject:[exif_dict objectForKey:key] forKey:key];
                    }
//                    if ([pluck containsObject:kDateTimeOriginalKey])
//                    {
//                        [dicData setObject:[CAssetsPickerPlugin date2str:date withFormat:DATETIME_FORMAT] forKey:kDateTimeOriginalKey];
//                    }
//                    if ([pluck containsObject:kPixelXDimensionKey])
//                    {
//                        [dicData setObject:@(pixelXDimension) forKey:kPixelXDimensionKey];
//                    }
//                    if ([pluck containsObject:kPixelYDimensionKey])
//                    {
//                        [dicData setObject:@(pixelYDimension) forKey:kPixelYDimensionKey];
//                    }
//                    if ([pluck containsObject:kOrientationKey])
//                    {
//                        [dicData setObject:[asset valueForProperty:ALAssetPropertyOrientation] forKey:kOrientationKey];
//                    }
                }
                
                // id
                [retAssets addObject:@{@"id": [CAssetsPickerPlugin getAssetId:asset] ,
                                       @"data": dicData}];
                
            }
            
            [dic setObject:retAssets forKey:kAssetsKey];
        }
        
        //pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:dic];
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:dic];
        //resultJS = [pluginResult toSuccessCallbackString:self.latestCommand.callbackId];
        //dispatch_async(dispatch_get_main_queue(), ^(){
        [self.commandDelegate runInBackground:^{
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        }];
        //});
    }];
    
}

#pragma mark - Utility Functions

- (void)initOptions
{
    // default values
    _quality = 75;
    _destType = DestinationTypeFileURI;
    _encodeType = EncodingTypeJPEG;
    _overlayIcons = [[NSMutableDictionary alloc] init];
    _overlays = [[NSMutableDictionary alloc] init];
    _targetWidth = -1;
    _targetHeight = -1;
    _correctOrientation = YES;
    _hightlightAssets = [[NSMutableDictionary alloc] init];
    _highlightDates = [[NSMutableArray alloc] init];
    _isDateBookmark = NO;
    _isThumbnail = NO;
    _popOverRect = CGRectMake(100, 100, 300, 200);
    _popOverDirection = UIPopoverArrowDirectionAny;
}

/**
 * parse options parameter and set it to local variables
 *
 */

- (void)getOptions: (NSDictionary *)jsonData
{
    // get parameters from argument.
 
    // quaility
    NSString *obj = [jsonData objectForKey:kQualityKey];
    if (obj != nil)
        _quality = [obj intValue];
    
    // destination type
    obj = [jsonData objectForKey:kDestinationTypeKey];
    if (obj != nil)
    {
        int destinationType = [obj intValue];
        NSLog(@"destinationType = %d", destinationType);
        _destType = destinationType;
    }
    
    // encoding type
    obj = [jsonData objectForKey:kEncodingTypeKey];
    if (obj != nil)
    {
        int encodingType = [obj intValue];
        _encodeType = encodingType;
    }
    
    // target width
    obj = [jsonData objectForKey:kTargetWidth];
    if (obj != nil)
    {
        _targetWidth = [obj intValue];
    }
    
    // target height
    obj = [jsonData objectForKey:kTargetHeight];
    if (obj != nil)
    {
        _targetHeight = [obj intValue];
    }
    
    // popover options
    obj = [jsonData objectForKey:kPopoverOptions];
    if (obj != nil && [obj isKindOfClass:[NSDictionary class]])
    {
        NSDictionary *popdic = (NSDictionary *)obj;
        int x = -1;
        int y = -1;
        int width = -1;
        int height = -1;
        UIPopoverArrowDirection dir = UIPopoverArrowDirectionAny;
        obj = [popdic objectForKey:kPopoverRectX];
        if (obj != nil)
        {
            x = [obj integerValue];
        }
        obj = [popdic objectForKey:kPopoverRectY];
        if (obj != nil)
        {
            y = [obj integerValue];
        }
        obj = [popdic objectForKey:kPopoverRectWidth];
        if (obj != nil)
        {
            width = [obj integerValue];
        }
        obj = [popdic objectForKey:kPopoverRectHeight];
        if (obj != nil)
        {
            height = [obj integerValue];
        }
        
        if (x == -1 || y == -1 || width == -1 || height == -1)
        {
            // ignore option
        }
        else
        {
            _popOverRect = CGRectMake(x, y, width, height);
        }
        
        obj = [popdic objectForKey:kPopoverArrowDir];
        if (obj != nil)
            dir = (UIPopoverArrowDirection) [obj integerValue];
        
        _popOverDirection = dir;
    }
    
    // overlay
    NSDictionary *overlay = [jsonData objectForKey:kOverlayKey];
    if (overlay != nil)
    {
        NSArray *keys = [overlay allKeys];
        for (int i = 0; i < [keys count]; i++) {
            NSString *key = [keys objectAtIndex:i];
            NSArray *value = [overlay objectForKey:key];
            
            NSMutableArray *arrayUrl = [[NSMutableArray alloc] init];
            // {overlayName, arrayOf "uuid.ext" items}
            for (NSString *uuid_ext in value) {
                NSArray *urlComponents = [uuid_ext componentsSeparatedByString:@"."];
                if ([urlComponents count] >= 2)
                {
                    NSString *uuid = [urlComponents objectAtIndex:0];
                    NSString *ext = [urlComponents objectAtIndex:1];
                    NSString *urlString = [CAssetsPickerPlugin getUrlStringWithUuid:uuid ext:ext];
                    [arrayUrl addObject:urlString];
                }
            }
            
            [_overlays setValue:arrayUrl forKey:key];
        }
    }
    
    // correctOrientation
    obj = [jsonData objectForKey:kCorrectOrientation];
    if (obj != nil)
    {
        _correctOrientation = [obj boolValue];
    }
    
    // bookmarks
    obj = [jsonData objectForKey:kBookmarks];
    if (obj != nil && ![obj isEqual:[NSNull alloc]])
    {
        NSDictionary *dic = (NSDictionary *)obj;
        NSArray *allKeys = [dic allKeys];
        for (NSString *key in allKeys) {
            if ([key isEqualToString:kBookmarksDate])
            {
                _isDateBookmark = YES;
                if (_hightlightAssets != nil)
                    [_hightlightAssets removeAllObjects];
                else
                    _hightlightAssets = [[NSMutableDictionary alloc] init];
                
                NSArray *arrayDates = [dic objectForKey:kBookmarksDate];
                if (arrayDates != nil && [arrayDates count] > 0)
                {
                    _highlightDates = [[NSMutableArray alloc] init];
                    for (NSString *strDate in arrayDates) {
                        NSDate *date = [CAssetsPickerPlugin str2date:strDate withFormat:@"yyyy-MM-dd"];
                        if (date)
                            [_highlightDates addObject:date];
                    }
                }
                else
                {
                    
                }
                break;
            }
        }
        
        if (!_isDateBookmark)
        {
            _hightlightAssets = [[NSMutableDictionary alloc] initWithDictionary:dic];
        }
    }
    else
    {
        if (_hightlightAssets != nil)
            [_hightlightAssets removeAllObjects];
        else
            _hightlightAssets = [[NSMutableDictionary alloc] init];
        _highlightDates = [[NSMutableArray alloc] init];
        
        _isDateBookmark = NO;
    }
    
    //thumbnail
    obj = [jsonData objectForKey:kThumbnailKey];
    if (obj != nil)
    {
        _isThumbnail = [obj boolValue];
    }
}

/**
 * objectFromAsset
 *
 * get return object from asset
 *
 */
- (NSDictionary *)objectFromAsset:(ALAsset *)asset fromThumbnail:(BOOL)fromThumbnail
{
     NSMutableDictionary* retValues = [NSMutableDictionary dictionaryWithCapacity:3];
    
    @autoreleasepool {
  
   
        NSString *strUrl = [NSString stringWithFormat:@"%@", [[asset valueForProperty:ALAssetPropertyAssetURL] absoluteString] ];
        // obj.id
        [retValues setObject:strUrl forKey:kIdKey];
        
        // obj.uuid
        NSString *uuidString = @"";
        URLParser *parser = [URLParser parserWithURL:[asset valueForProperty:ALAssetPropertyAssetURL]];
        uuidString = [NSString stringWithFormat:@"%@", [parser valueForKey:@"id"]]; // ?id=xxx-xx&ext=JPG
        [retValues setObject:uuidString forKey:kUuidKey];
        
        // obj.orig-ext
        NSString *ext = [NSString stringWithFormat:@"%@", [parser valueForKey:@"ext"]];
        [retValues setObject:ext forKey:kOrigExtKey];
        
        // obj.label
        NSString *filename = [NSString stringWithFormat:@"%@", [[asset defaultRepresentation] filename]];
        [retValues setObject:filename forKey:kLabelKey];
        
        // obj.data
        NSData *data = nil;
        NSString *newExt = nil;
        UIImage *image = nil;
        
        
        // if from thumbnail, then no scaling
        if (fromThumbnail)
        {
            image = [UIImage imageWithCGImage:asset.thumbnail];
            CGSize szImage = image.size;
            szImage = szImage;
        }
        else
        {
            image = [UIImage imageWithCGImage:asset.defaultRepresentation.fullResolutionImage scale:1.0 orientation:(UIImageOrientation)asset.defaultRepresentation.orientation];
        
            // scale image with targetW/H
            if (_targetWidth <= 0 && _targetHeight <= 0)
            {
                image = image;
            }
            else if (_targetWidth <= 0)
            {
                CGFloat scale = _targetHeight / image.size.height;
                image = [CAssetsPickerPlugin scaleImage:image scale:scale];
            }
            else if (_targetHeight <= 0)
            {
                CGFloat scale = _targetWidth / image.size.width;
                image = [CAssetsPickerPlugin scaleImage:image scale:scale];
            }
            else
            {
                CGFloat scaleX = _targetWidth / image.size.width;
                CGFloat scaleY = _targetHeight / image.size.height;
                
                CGFloat scale = scaleX;
                if (scaleX > scaleY)
                {
                    scale = scaleY;
                }
                image = [CAssetsPickerPlugin scaleImage:image scale:scale];
            }
        }
        
        // Get the image data (blocking; around 1 second)
        if (_encodeType == EncodingTypeJPEG)
        {
            newExt = EXT_JPG;
            data = UIImageJPEGRepresentation(image, _quality / 100.0f);
        }
        else
        {
            newExt = EXT_PNG;
            data = UIImagePNGRepresentation(image);
        }
        
        if (_destType == DestinationTypeDataURL) {
            NSString *strEncoded = @"";
            
            strEncoded = [data base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
            
            [retValues setObject:strEncoded forKey:kDataKey];
        }
        else {
            //from http://codrspace.com/vote539/writing-a-custom-camera-plugin-for-phonegap/
            
            // Get a file path to save the JPEG
            NSString *imagePath = [CAssetsPickerPlugin getFilePath:uuidString ext:newExt];
            
            // Write the data to the file
            [data writeToFile:imagePath atomically:YES];
            
            imagePath = [NSString stringWithFormat:@"file://%@", imagePath];
            
            //[retValues setObject:strUrl forKey:kDataKey];
            [retValues setObject:imagePath forKey:kDataKey];
        }
#if false
        // obj.exif
        NSMutableDictionary *exif = [NSMutableDictionary dictionaryWithCapacity:4];
        
        // obj.exif.DateTimeOriginal
        NSDate *date = [asset valueForProperty:ALAssetPropertyDate];
        if (date != nil)
        {
            [exif setObject:[CAssetsPickerPlugin date2str:date withFormat:DATETIME_FORMAT] forKey:kDateTimeOriginalKey];
        }
        else
        {
            [exif setObject:@"" forKey:kDateTimeOriginalKey];
        }
        
        //obj.exif.PixelXDimension
        //obj.exif.PixelYDimension
        if (_destType == DestinationTypeDataURL)
        {
            //
            if (asset.defaultRepresentation != nil)
            {
                [exif setObject:@(asset.defaultRepresentation.dimensions.width) forKey:kPixelXDimensionKey];
                [exif setObject:@(asset.defaultRepresentation.dimensions.height) forKey:kPixelYDimensionKey];
            }
            else
            {
                [exif setObject:@(0) forKey:kPixelXDimensionKey];
                [exif setObject:@(0) forKey:kPixelYDimensionKey];
            }
        }
        else
        {
            if (asset.defaultRepresentation != nil)
            {
                [exif setObject:@(asset.defaultRepresentation.dimensions.width) forKey:kPixelXDimensionKey];
                [exif setObject:@(asset.defaultRepresentation.dimensions.height) forKey:kPixelYDimensionKey];
            }
            else
            {
                [exif setObject:@(0) forKey:kPixelXDimensionKey];
                [exif setObject:@(0) forKey:kPixelYDimensionKey];
            }
        }
        
        //obj.exif.Orientation
        [exif setObject:[asset valueForProperty:ALAssetPropertyOrientation] forKey:kOrientationKey];
#else
        NSDictionary *exif = [CAssetsPickerPlugin getExif:asset];
#endif
        
        
        [retValues setObject:exif forKey:kExifKey];
    }; // end autorelease pool
    
    
    return retValues;
}


#pragma mark - Assets Picker Delegate

/**
 *  the user finish picking photos or videos.
 *
 *  @param picker The controller object managing the assets picker interface.
 *  @param assets An array containing picked `ALAsset` objects.
 */
- (void)assetsPickerController:(CTAssetsPickerController *)picker didFinishPickingAssets:(NSArray *)assets
{
    if (self.popover != nil)
        [self.popover dismissPopoverAnimated:YES];
    else
        [picker.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    
    // Unset the self.hasPendingOperation property
	self.hasPendingOperation = NO;
    
    CDVPluginResult *pluginResult = nil;
    NSString *resultJS = nil;
    
    // make array of return objects
    NSMutableArray *retArray = [[NSMutableArray alloc] init];
    for (int i = 0; i < assets.count; i++)
    {
        ALAsset *asset = [assets objectAtIndex:i];
        NSDictionary *retValues = [self objectFromAsset:asset fromThumbnail:_isThumbnail];
        [retArray addObject:retValues];
    }
    
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:retArray];
    resultJS = [pluginResult toSuccessCallbackString:self.latestCommand.callbackId];
    [self writeJavascript:resultJS];
}


/**
 *  the user cancelled the pick operation.
 *
 *  @param picker The controller object managing the assets picker interface.
 */
- (void)assetsPickerControllerDidCancel:(CTAssetsPickerController *)picker
{
    // Unset the self.hasPendingOperation property
	self.hasPendingOperation = NO;

    
    CDVPluginResult *pluginResult = nil;
    NSString *resultJS = nil;
    
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"Canceled!"];
    resultJS = [pluginResult toErrorCallbackString:self.latestCommand.callbackId];
    [self writeJavascript:resultJS];
}

- (BOOL)assetsPickerController:(CTAssetsPickerController *)picker shouldEnableAssetForSelection:(ALAsset *)asset
{
    // disable video clips
    if ([[asset valueForProperty:ALAssetPropertyType] isEqual:ALAssetTypeVideo])
    {
        // Enable video clips if they are at least 5s
        //NSTimeInterval duration = [[asset valueForProperty:ALAssetPropertyDuration] doubleValue];
        //return lround(duration) >= 5;
        return NO;
    }
    else
    {
        return YES;
    }
}

- (BOOL)assetsPickerController:(CTAssetsPickerController *)picker shouldSelectAsset:(ALAsset *)asset
{
    /*
    if (picker.selectedAssets.count >= 10)
    {
        UIAlertView *alertView =
        [[UIAlertView alloc] initWithTitle:@"Attention"
                                   message:@"Please select not more than 10 assets"
                                  delegate:nil
                         cancelButtonTitle:nil
                         otherButtonTitles:@"OK", nil];
        
        [alertView show];
    }
     */
    
    if (!asset.defaultRepresentation)
    {
        UIAlertView *alertView =
        [[UIAlertView alloc] initWithTitle:@"Attention"
                                   message:@"Your asset has not yet been downloaded to your device"
                                  delegate:nil
                         cancelButtonTitle:nil
                         otherButtonTitles:@"OK", nil];
        
        [alertView show];
    }
    
    //return (picker.selectedAssets.count < 10 && asset.defaultRepresentation != nil);
    return (asset.defaultRepresentation != nil);
     
    return YES;
}

#pragma mark - Popover Controller Delegate

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    self.popover = nil;
}

#pragma mark - Common Function

+ (NSString *)date2str:(NSDate *)convertDate withFormat:(NSString *)formatString
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:formatString];
    
    return [dateFormatter stringFromDate:convertDate];
}

+ (UIImage *)scaleImage:(UIImage *)image scale:(CGFloat)scale
{
    CGSize newSize;
    newSize.width = image.size.width * scale;
    newSize.height = image.size.height *scale;
    UIGraphicsBeginImageContext(newSize);
    [image drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

+ (NSString *)getAppPath
{
    // Get a file path to save the JPEG
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* documentsDirectory = [paths objectAtIndex:0];
    NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:@"/tmp"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:dataPath])
    {
        NSError *error = nil;
        [[NSFileManager defaultManager] createDirectoryAtPath:dataPath withIntermediateDirectories:NO attributes:nil error:&error]; //Create folder
        if (error) {
            NSLog(@"error occurred in create tmp folder : %@", [error localizedDescription]);
        }
    }
    return dataPath;
}

+ (NSString *)getFilePath:(NSString *)uuidString ext:(NSString *)ext
{
    NSString *documentsDirectory = [CAssetsPickerPlugin getAppPath];
    NSString* filename = [NSString stringWithFormat:@"%@.%@", uuidString, ext];
    NSString* imagePath = [documentsDirectory stringByAppendingPathComponent:filename];
    return imagePath;
}

+ (NSURL *)getUrlFromUrlString:(NSString *)urlString
{
    NSURL *url = [NSURL URLWithString:urlString];
    return url;
}

+ (NSString *)getUrlStringWithUuid:(NSString *)uuid ext:(NSString *)ext;
{
    NSString *urlString = [NSString stringWithFormat:@"assets-library://asset/asset.%@?id=%@?ext=%@", ext, uuid, ext];
    return urlString;
}

+ (NSDate *)str2date:(NSString *)dateString withFormat:(NSString *)formatString
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:formatString];
    return [dateFormatter dateFromString:dateString];
}

+ (NSString *)getAssetId:(ALAsset *)asset
{
    // obj.uuid
    NSString *uuidString = @"";
    
    URLParser *parser = [URLParser parserWithURL:[asset valueForProperty:ALAssetPropertyAssetURL]];
    uuidString = [NSString stringWithFormat:@"%@", [parser valueForKey:@"id"]]; // ?id=xxx-xx&ext=JPG
    
    // obj.orig-ext
    NSString *ext = [NSString stringWithFormat:@"%@", [parser valueForKey:@"ext"]];
    
    NSString *assetId = [NSString stringWithFormat:@"%@.%@", uuidString, ext];
    return assetId;
}

+ (NSMutableDictionary *)getExif:(ALAsset *)asset
{
    ALAssetRepresentation *image_representation = [asset defaultRepresentation];
    
    // create a buffer to hold image data
    uint8_t *buffer = (Byte*)malloc(image_representation.size);
    NSUInteger length = [image_representation getBytes:buffer fromOffset: 0.0  length:image_representation.size error:nil];
    NSMutableDictionary *exif_dict = [[NSMutableDictionary alloc] init];
    if (length != 0)  {
        
        // buffer -> NSData object; free buffer afterwards
        NSData *adata = [[NSData alloc] initWithBytesNoCopy:buffer length:image_representation.size freeWhenDone:YES];
        
        // identify image type (jpeg, png, RAW file, ...) using UTI hint
        NSDictionary* sourceOptionsDict = [NSDictionary dictionaryWithObjectsAndKeys:(id)[image_representation UTI] ,kCGImageSourceTypeIdentifierHint,nil];
        
        // create CGImageSource with NSData
        CGImageSourceRef sourceRef = CGImageSourceCreateWithData((__bridge CFDataRef) adata,  (__bridge CFDictionaryRef) sourceOptionsDict);
        
        // get imagePropertiesDictionary
        CFDictionaryRef imagePropertiesDictionary;
        imagePropertiesDictionary = CGImageSourceCopyPropertiesAtIndex(sourceRef,0, NULL);
        
        // get exif data
        CFDictionaryRef exif = (CFDictionaryRef)CFDictionaryGetValue(imagePropertiesDictionary, kCGImagePropertyExifDictionary);
        exif_dict = [[NSMutableDictionary alloc] initWithDictionary:(__bridge NSDictionary*)exif];
//        NSLog(@"exif_dict: %@", exif_dict);
        
//        // save image WITH meta data
//        NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
//        NSURL *fileURL = nil;
//        CGImageRef imageRef = CGImageSourceCreateImageAtIndex(sourceRef, 0, imagePropertiesDictionary);
//        
//        if (![[sourceOptionsDict objectForKey:@"kCGImageSourceTypeIdentifierHint"] isEqualToString:@"public.tiff"])
//        {
//            fileURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@.%@",
//                                              documentsDirectory,
//                                              @"myimage",
//                                              [[[sourceOptionsDict objectForKey:@"kCGImageSourceTypeIdentifierHint"] componentsSeparatedByString:@"."] objectAtIndex:1]
//                                              ]];
//            
//            CGImageDestinationRef dr = CGImageDestinationCreateWithURL ((__bridge CFURLRef)fileURL,
//                                                                        (__bridge CFStringRef)[sourceOptionsDict objectForKey:@"kCGImageSourceTypeIdentifierHint"],
//                                                                        1,
//                                                                        NULL
//                                                                        );
//            CGImageDestinationAddImage(dr, imageRef, imagePropertiesDictionary);
//            CGImageDestinationFinalize(dr);
//            CFRelease(dr);
//        }
//        else
//        {
//            NSLog(@"no valid kCGImageSourceTypeIdentifierHint found …");
//        }
        
        // clean up
//        CFRelease(imageRef);
        //CFRelease(exif);
        CFRelease(imagePropertiesDictionary);
        CFRelease(sourceRef);
    }
    else {
        NSLog(@"image_representation buffer length == 0");
    }
    
    
    
    // DateTimeOriginal
    if ([exif_dict objectForKey:(__bridge NSString *)kCGImagePropertyExifDateTimeOriginal] == nil)
    {
        NSDate *date = [asset valueForProperty:ALAssetPropertyDate];
        if (date != nil)
        {
            [exif_dict setObject:[CAssetsPickerPlugin date2str:date withFormat:DATETIME_EXIF_FORMAT] forKey:(__bridge NSString *)kCGImagePropertyExifDateTimeOriginal];
        }
    }

    
    // PixelXDimension
    if ([exif_dict objectForKey:(__bridge NSString *)kCGImagePropertyExifPixelXDimension] == nil)
    {
        if (asset.defaultRepresentation != nil)
            [exif_dict setObject:@(asset.defaultRepresentation.dimensions.width) forKey:(__bridge NSString *)kCGImagePropertyExifPixelXDimension];
    }

    
    // PixelYDimension
    if ([exif_dict objectForKey:(__bridge NSString *)kCGImagePropertyExifPixelYDimension] == nil)
    {
        if (asset.defaultRepresentation != nil)
            [exif_dict setObject:@(asset.defaultRepresentation.dimensions.height) forKey:(__bridge NSString *)kCGImagePropertyExifPixelYDimension];
    }

    //Orientation
    if ([exif_dict objectForKey:kOrientationKey] == nil)
    {
        [exif_dict setObject:[asset valueForProperty:ALAssetPropertyOrientation] forKey:kOrientationKey];
    }
    
    NSLog(@"exif_dict: %@", exif_dict);
    
    return exif_dict;
}

@end
