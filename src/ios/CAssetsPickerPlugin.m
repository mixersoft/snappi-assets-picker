//
//  CAssetsPickerPlugin.m
//  AssetsPlugin
//
//  Created by Donald Pae on 4/22/14.
//
//

#import "CAssetsPickerPlugin.h"
#import "URLParser.h"
#import "UIManager.h"

#define EXT_JPG     @"JPG"
#define EXT_PNG     @"PNG"


@implementation CAssetsPickerPlugin {
    int _quality;
    DestinationType _destType;
    EncodingType _encodeType;
    NSDictionary *_overlays;    // {overlayName, array of assetIds}
    NSDictionary *_overlayIcons;
    NSURL *_assetURL;
    NSString *_uuid;
    int _targetWidth;
    int _targetHeight;
    BOOL _correctOrientation;
}

#pragma  mark - Interfaces

- (void)getPicture:(CDVInvokedUrlCommand *)command
{
    // Set the hasPendingOperation field to prevent the webview from crashing
	self.hasPendingOperation = YES;
    
	// Save the CDVInvokedUrlCommand as a property.  We will need it later.
	self.latestCommand = command;
    
    self.picker = [[CTAssetsPickerController alloc] init];
    self.picker.assetsFilter         = [ALAssetsFilter allAssets];
    self.picker.showsCancelButton    = (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad);
    self.picker.delegate             = self;
    
    [self initOptions];
    if ([command.arguments count]> 0)
    {
        NSDictionary *jsonData = [command.arguments objectAtIndex:0];
        [self getOptions:jsonData];
    }
    
    // set selected assets
    NSArray *selectedAssetObjs = [_overlays objectForKey:kPreviousSelectedName];
    if (selectedAssetObjs != nil)
        self.picker.selectedAssetObjs = [[NSMutableArray alloc] initWithArray:selectedAssetObjs];
    else
        self.picker.selectedAssetObjs  = [[NSMutableArray alloc] init];
    
    // iPad
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        self.popover = [[UIPopoverController alloc] initWithContentViewController:self.picker];
        self.popover.delegate = self;
        CGRect frame = CGRectMake(100, 100, 300, 200); // self.viewController.view.frame
        [self.popover presentPopoverFromRect:frame inView:self.viewController.view permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
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
        
            NSDictionary *retValues = [self objectFromAsset:asset fromThumbnail:NO];
            
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
            [UIManager sharedManager].overlayIcon = [UIImage imageWithData:iconData scale:[UIScreen mainScreen].scale];
            bRet = YES;
            
            if (iconData != nil)
                [_overlayIcons setValue:iconData forKey:overlayName];
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
    
}

- (NSDictionary *)objectFromAsset:(ALAsset *)asset fromThumbnail:(BOOL)fromThumbnail
{
    NSMutableDictionary* retValues = [NSMutableDictionary dictionaryWithCapacity:3];
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
    
    if (fromThumbnail)
        image = [UIImage imageWithCGImage:asset.thumbnail];
    else
        image = [UIImage imageWithCGImage:asset.defaultRepresentation.fullResolutionImage];
    
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
    
    [retValues setObject:exif forKey:kExifKey];
    
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
        //NSDictionary *retValues = [self objectFromAsset:asset fromThumbnail:YES];
        NSDictionary *retValues = [self objectFromAsset:asset fromThumbnail:NO];
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

@end
