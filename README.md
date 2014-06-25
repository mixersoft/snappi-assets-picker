snappi-assets-picker
============================

Multiple select assets picker for iOS, supports multiple selection of photos from album using [CTAssetsPickerController][ctassetspickercontroller]. API specs is following [cordova-plugin-local-notifications][cordova-plugin-local-notifications]

### Plugin's Purpose
The purpose of the plugin is to create a fast and reliable view of photos on the mobile phones.


## Supported Platforms
- **iOS**<br>

## Dependencies
[Cordova][cordova] will check all dependencies and install them if they are missing.


## Installation
The plugin can either be installed into the local development environment or cloud based through [PhoneGap Build][PGB].

### Adding the Plugin to your project
Through the [Command-line Interface][CLI]:
```bash
# ~~ from master ~~
cordova plugin add https://github.com/mixersoft/snappi-assets-picker.git && cordova prepare
```
or to use the last stable version:
```bash
# ~~ stable version ~~
cordova plugin add com.michael.cordova.plugin.assets-picker && cordova prepare
```

### Removing the Plugin from your project
Through the [Command-line Interface][CLI]:
```bash
cordova plugin rm com.michael.cordova.plugin.assets-picker
```

### PhoneGap Build
Add the following xml to your config.xml to always use the latest version of this plugin:
```xml
<gap:plugin name="com.michael.cordova.plugin.assets-picker" />
```
or to use an specific version:
```xml
<gap:plugin name="com.michael.cordova.plugin.assets-picker" version="0.8.1" />
```
More informations can be found [here][PGB_plugin].


## ChangeLog

#### Version 0.8.1 (not yet released)
- [feature:] added FILE_URI feature
- [feature:] added getById function
- [enhanced:] changed parameter "selectedAssets" of options to "overlay"

#### Version 0.8.0 (not yet released)
- [feature:] Create plugin


## Using the plugin
The plugin creates the object ```window.plugin.snappi.assetspicker``` with the following methods:

### Plugin initialization
The plugin and its methods are not available before the *deviceready* event has been fired.

```javascript
document.addEventListener('deviceready', function () {
    // window.plugin.snappi.assetspicker is now available
}, false);
```

### getPicture
Retrieves multiple photos from the device's album.<br>
Selected images are returned as an array of identifiers of image, image data (or URIs) and exif of image files.<br>

```javascript
window.plugin.snappi.assetspicker.getPicture(onSuccess, onCancel, options);
```

This function opens photo chooser dialog, from which multiple photos from the album can be selected.
The return array will be sent to the [onSuccess][onsuccess] function, each item has dictionary value as following formats;
```javascript
{
id : identifier,
uuid : uuid,
label : label,
orig_ext : orig_ext, 
data : imageData,
exif : {
    DateTimeOriginal : dateTimeOriginal,
    PixelXDimension : pixelXDimension,
    PixelYDimension : pixelYDimension,
    Orientation : orientation
};
```

##### id
identifier string of selected photo. This is url of the asset which format is as ```assets-library://asset/asset.JPG?id=12345678-1234-1342-52DB-ABE03FDF1234&ext=JPG```.

##### uuid
uuid of selected photo. Asset has format ```assets-library://asset/asset.{ext}?id={uuid}&ext={ext}```. uuid is unique identifier of this photo.
When you get picture with FILE_URI (options.destinationType == Camera.DestinationType.FILE_URI), then the plugin make a new file named as {uuid}.{encodingType} on the plugin space and returns the path of this file as data value. for instance, options.encodingType = JPEG and uuid = 12345678-1234-1342-52DB-ABE03FDF1234, then new file is named as "12345678-1234-1342-52DB-ABE03FDF1234.JPG".
Javascript functions can access this new image file using URL(data value) directly.

##### label
File name of the original image file. Photos are saved as "IMG_xxxxx.JPG" in general and the plugin returns this name of file like "IMG_00001.JPG".

##### orig_ext
Original extension of image file. This value is used for [getById][getById] function. The corresponding value would be "JPG" or "PNG".


##### data
The data of image is one of the following formats, depending on the options you specify:
- A String containing the Base64 encoded photo image.
- A String representing the image file location on local storage (default).

##### exif
- DateTimeOriginal : datetime when the image was taken. formatted as "yyyy-MM-dd HH:mm:ss" ("2014-01-31 11:02:59")
- PixelXDimension : width (pixels) of the image.
- PixelYDimension : height (pixels) of the image.
- Orientation : The key to retrieve the orientation of the asset. The corresponding value is an number containing an asset's orientation as described by the TIFF format.

#### Example
```javascript
function pickPictures()
{
    var options = {
        quality: 75,
        destinationType: Camera.DestinationType.DATA_URL,
        encodingType: Camera.EncodingType.JPEG,
        targetWidth: 100,
        targetHeight: 100
    };
    window.plugin.snappi.assetspicker.getPicture(onSuccess, onCancel, options);
}
```

### getById
Retrieve a photo with uuid of asset.<br>

```javascript
window.plugin.snappi.assetspicker.getById(uuid, [orig_ext,] onGetById, onCancel, options);
```

This function gets a Assets with uuid. If orig_ext parameter is not specified, then default value (JPG) is set.
The return picture will be sent to the [onGetById][ongetbyid] function, returned picture is a dictionary value as following formats;
```javascript
{
id : identifier,
uuid : uuid,
label : label,
orig_ext : orig_ext,
data : imageData,
exif : {
    DateTimeOriginal : dateTimeOriginal,
    PixelXDimension : pixelXDimension,
    PixelYDimension : pixelYDimension,
    Orientation : orientation
};
```

##### Parameters
Same as an item of returned array on [onSuccess][onsuccess] callback.

#### Example
```javascript
function getAPictureWithId(uuid, orig_ext)
{
    var options = {
        quality: 75,
        destinationType: Camera.DestinationType.DATA_URL,
        encodingType: Camera.EncodingType.JPEG,
        targetWidth: 100,
        targetHeight: 100
    };
    window.plugin.snappi.assetspicker.getById(uuid, orig_ext, onGetById, onCancel, options);
}
```

### setOverlay
Set overlay icon.<br>

```javascript
window.plugin.snappi.assetspicker.setOverlay(overlayName, iconBase64Encoded);
```
##### overlayName
The corresponding name of overlay. Now it has to be set as `Camera.Overlay.PREVIOUS_SELECTED`.

##### iconBase64Encoded
Base64 encoded icon image data.
You can get base64 encoded icon image data from <img> tag as following;
```javascript
function getBase64Image(img)
{
     // Create an empty canvas element
     var canvas = document.createElement("canvas");
     canvas.width = img.width;
     canvas.height = img.height;
            
     // Copy the image contents to the canvas
     var ctx = canvas.getContext("2d");
     ctx.drawImage(img, 0, 0);
            
     // Get the data-URL formatted image
     // Firefox supports PNG and JPEG. You could check img.src to
     // guess the original format, but be aware the using "image/jpg"
     // will re-encode the image.
     var dataURL = canvas.toDataURL("image/png");
         
     return dataURL.replace(/^data:image\/(png|jpg);base64,/, "");
}
```


#### Example
```javascript
function onSetOverlay()
{
    var overlayIcon = getBase64Image(document.getElementById("overlay"));
    window.plugin.snappi.assetspicker.setOverlay(Camera.Overlay.PREVIOUS_SELECTED, overlayIcon, function(){}, function(msg){alert("failure in setOverlay:" + msg);});
}
```


### getPreviousAlbums
Get previous focused albums & assets. 
```javascript
window.plugin.snappi.assetspicker.getPreviousAlbums(success, failure);
```

This function returns dictionary object that contains items formatted as following;
```javascript
item : { albumID: assetID} 
```
If user set this dictionary object to [options.bookmarks][options], then the plugin show previous focused asset when open the corresponding album.

#### albumID
unique identifier of album

#### assetID
unique identifier of focused asset.

#### success
The corresponding function is called when getting is success.

#### Example
```javascript
function getPreviousAlbums()
{
   // get previous albums
    window.plugin.snappi.assetspicker.getPreviousAlbums(onGetPreviousAlbumsSuccess, onGetPreviousAlbumsFailure);
}

function onGetPreviousAlbumsFailure(msg)
{
    alert(msg);
}
        
function onGetPreviousAlbumsSuccess(result)
{
    previousAlbums = result;
}
```

### mapAssetsLibrary
 The initial purpose of this method is to get a list of every photo on the device by EXIF DateOriginalTaken, but a JS callback may be more flexible. It should be similar to _.pick, see http://lodash.com/docs#pick

```
mapAssetsLibrary(success, failure, options):

  options.pluck = [array of exif attributes]
  // add limits to map 
  options.fromDate = [JSON string of date]; // see the following getJSONStringOfDate()
  option.toDate = [JSON string of date]; // see the following getJSONStringOfDate()

get object in the following form:
mapped = {
    // use lastDate as options.fromDate to limit map
    lastDate: [Date]
    assets: [{
        id: [AlAssetsId - uuid.ext]
        data: { plucked attributes }
    }
    ]
}

example: 
   window.plugin.snappi.assetspicker.mapAssetsLibrary(onMapSuccess, onMapFailed, {
      pluck:['DateTimeOriginal', 'PixelXDimension']
      fromDate: "2014-04-24T03:31:24.524Z"
   });

   function onMapSuccess(mapped)
   {
   	// mapped.lastDate : "2014-06-17 05:12:36"
	// mapped.assets = [array of item] in the following form:
	//	{ 
	//	  id:   ALAssetsId, 
	//	  data: {plucked attributes}
	//      }
   }

   // get JSON string of date in local-timezone(not UTC)
   function getJSONStringOfDate()
   {
	x = new Date();
	x.setHours(x.getHours() - x.getTimezoneOffset() / 60);
	return x.toJSON();
   }
```

#### success
The corresponding function is called when mapping is success.
```
onMapSuccess(mapped)
{
	//
}
```
mapped is result object of mapAssetsLibrary.
```
mapped = {
    // use lastDate as options.fromDate to limit map
    lastDate: [Date]
    assets: [{
        id: [AlAssetsId]
        data: { plucked attributes }
    }
    ]
}

```
- lastDate : Date of last asset in the mapped array. The corresponding value is in the form "yyyy-MM-dd".
- id : URL string of asset. The corresponding value is unique identifier of asset.
- data : {plucked attributes}. exif attributes that are specified options parameter.

#### failure
The corresponding function is called when mapping is failed.

#### options
The corresponding parameter is in the following form:
```
options = {
	pluck : [array of exif attributes], when this is not specified, then take every exif attributes
	fromDate : start date with JSON date format in local-timezone, when this is not specified, then ignore start date.
	toDate : end date with JSON date format in local-timezone, when this is not specified, then ignore end date.
}

Caller can use the following function to get JSON string of date in local-timezone for fromDate and toDate
   // get JSON string of date in local-timezone(not UTC)
   function getJSONStringOfDate()
   {
	x = new Date();
	x.setHours(x.getHours() - x.getTimezoneOffset() / 60);
	return x.toJSON();
   }
```


### onSuccess
onSuccess callback function that provides the selected images.
```javascript
function(dataArray) {
    // Do something with the images
}
```
#### Parameters
- dataArray: array of image with identifier and image data
```javascript
{
id : identifier,	// unique identifier string of the image. (String)
uuid : uuid,		// uuid of the image. (String)
label : label,		// file name of the image. (String)
orig_ext : orig_ext,	// extension of the image file. [JPG | PNG]
data : imageData,	// image data, Base64 encoding of the image data, OR the image file URI, depending on options used. (String)
exif : {
    /*DateTimeOriginal : dateTimeOriginal, 	// datetime when the image was taken
    PixelXDimension : pixelXDimension,		// width (pixels) of the image
    PixelYDimension : pixelYDimension,		// height (pixels) of the image
    Orientation : orientation			// orientation number*/
    {dictionary format of EXIF attributes if exist in the image} // EXIF attributes is defined on https://developer.apple.com/library/ios/documentation/graphicsimaging/reference/CGImageProperties_Reference/Reference/reference.html#//apple_ref/doc/constant_group/EXIF_Dictionary_Keys

};
```

#### Example
```javascript
// Show selected images
//
function onSuccess(dataArray) {
    for (i = 0; i <= dataArray.length; i++) {
         var item = dataArray[i];
         var imageId = item.id;
         
         // get picture by Id
         window.plugin.snappi.assetspicker.getById(item.uuid, item.orig_ext, onGetById, onCancel, options);
    }
}
```


### onCancel
onCancel callback function that provides a cancel or error message.
```javascript
function(message) {
    // Show a helpful message
    alert(message);
}
```
#### Parameters
- message: The message is provided by the device. (String)


### onGetById
onGetById callback function that provide the selected image.
```javascript
function(imageData) {
    // Do something with the image
}
```
#### Parameters
- imageData: image data of selected image, just like an item of returned array on [onSucess][onsuccess] callback.
```javascript
{
id : identifier,	// unique identifier string of the image. (String)
uuid : uuid,		// uuid of the image. (String)
label : label,		// file name of the image. (String)
orig_ext : orig_ext,	// extension of the image file. [JPG | PNG]
data : imageData,	// image data, Base64 encoding of the image data, OR the image file URI, depending on options used. (String)
exif : {
    /*
    DateTimeOriginal : dateTimeOriginal, 	// datetime when the image was taken
    PixelXDimension : pixelXDimension,		// width (pixels) of the image
    PixelYDimension : pixelYDimension,		// height (pixels) of the image
    Orientation : orientation			// orientation number*/
    {dictionary format of EXIF attributes if exist in the image} // EXIF attributes is defined on https://developer.apple.com/library/ios/documentation/graphicsimaging/reference/CGImageProperties_Reference/Reference/reference.html#//apple_ref/doc/constant_group/EXIF_Dictionary_Keys
};
```

#### Example
```javascript
// Show selected images
//
function onGetById(imageData) {
    var image = document.getElementById(imageData.id);
    image.src = "data:image/jpeg;base64," + imageData.data;
}
```

### options
Optional parameters to customize the settings.
```javascript
{ quality : 75, 
  destinationType : Camera.DestinationType.DATA_URL, 
  sourceType : Camera.PictureSourceType.CAMERA, 
  allowEdit : true,
  encodingType: Camera.EncodingType.JPEG,
  targetWidth: 100,
  targetHeight: 100,
  popoverOptions: CameraPopoverOptions,
  saveToPhotoAlbum: false,
  scrollToDate: new Date(),
  thumbnail : isThumbnail,
  overlay: {overlayName: array of "uuid.ext"}
  bookmarks: {albumID1:assetID1, albumID2:assetID2, …} // or {date:[array of dates]}
  };
```

- quality: Quality of saved image. Range is [0, 100]. (Number)
- destinationType: Choose the format of the return value. Defined in Camera.DestinationType (Number)
```javascript
    Camera.DestinationType = {
        DATA_URL : 0,                // Return image as base64 encoded string
        FILE_URI : 1                 // Return image file URI
    };
```
- sourceType: Set the source of the picture. Defined in Camera.PictureSourceType (Number)
```javascript
Camera.PictureSourceType = {
    PHOTOLIBRARY : 0,
    CAMERA : 1,
    SAVEDPHOTOALBUM : 2
};
```
- allowEdit: Allow simple editing of image before selection. (Boolean)
- encodingType: Choose the encoding of the returned image file. Defined in Camera.EncodingType (Number)
```javascript
    Camera.EncodingType = {
        JPEG : 0,               // Return JPEG encoded image
        PNG : 1                 // Return PNG encoded image
    };
```
- targetWidth: Width in pixels to scale image. Could be used with targetHeight. Aspect ratio is keeped. (Number)
- targetHeight: Height in pixels to scale image. Could be used with targetWidth. Aspect ratio is keeped. (Number)
- thumbnail: Flag option to select source image as original image(false) or thumbnail image(true). Default value is false. When set this flag, targetWidth/targetHeight options are ignored.
- mediaType: Set the type of media to select from. Only works when PictureSourceType is PHOTOLIBRARY or SAVEDPHOTOALBUM. Defined in nagivator.camera.MediaType (Number)
```javascript
Camera.MediaType = { 
    PICTURE: 0,             // allow selection of still pictures only. DEFAULT. Will return format specified via DestinationType
    VIDEO: 1,               // allow selection of video only, WILL ALWAYS RETURN FILE_URI
    ALLMEDIA : 2            // allow selection from all media types
};
```
- correctOrientation: Rotate the image to correct for the orientation of the device during capture. (Boolean)
- saveToPhotoAlbum: Save the image to the photo album on the device after capture. (Boolean)
- scrollToDate: Scroll to indicated date when open photo chooser dialog.
- overlay: Array of "uuid.ext" of images to be with overlay. Show overlay icons on these images when open photo chooser dialog. IDs could be returned [onSuccess][onsuccess] callback. 
- bookmarks: Dictionary object of key-value ```{albumID:assetID}``` or ```{date:[array of dates]}``` to bookmark specified asset on the corresponding album or to bookmark specified dates
- popoverOptions: iOS only options to specify popover location in iPad. Defined in CameraPopoverOptions.

#### CameraPopoverOptions

Parameters only used by iOS to specify the anchor element location and arrow direction of popover used on iPad when selecting images from the library or album.
```javascript
{ x : 280, 
  y :  220,
  width : 320,
  height : 480,
  arrowDir : Camera.PopoverArrowDirection.ARROW_ANY,
  popoverWidth : 500,
  popoverHeight : 500
};
```

- x: x pixel coordinate of element on the screen to anchor popover onto. (Number)
- y: y pixel coordinate of element on the screen to anchor popover onto. (Number)
- width: width, in pixels, of the element on the screen to anchor popover onto. (Number)
- height: height, in pixels, of the element on the screen to anchor popover onto. (Number)
- arrowDir: Direction the arrow on the popover should point. Defined in Camera.PopoverArrowDirection (Number)
 You can use this value to force the popover to be positioned on a specific side of the rectangle(x, y, width, height).
```javascript
    Camera.PopoverArrowDirection = {
        ARROW_UP : 1,        // matches iOS UIPopoverArrowDirection constants
        ARROW_DOWN : 2,
        ARROW_LEFT : 4,
        ARROW_RIGHT : 8,
        ARROW_ANY : 15
    };
```
- popoverWidth : Width of popover
- popoverHeight : Height of popover

#### Example
```javascript
 var popover = new CameraPopoverOptions(300,300,100,100,Camera.PopoverArrowDirection.ARROW_ANY);
 var options = { quality: 50, destinationType: Camera.DestinationType.DATA_URL,sourceType: Camera.PictureSource.SAVEDPHOTOALBUM, popoverOptions : popover };

 navigator.camera.getPicture(onSuccess, onCancel, options);

 function onSuccess(dataArray) {
	for (i = 0; i <= dataArray.length; i++) {
         var item = dataArray[i];
         var imageId = item.id;
         var image = document.getElementById(imageId);
         image.src = "data:image/jpeg;base64," + item.data;
    }
 }

 function onCancel(message) {
     alert('Failed because: ' + message);
 }
```

## Full Example
```html
<!DOCTYPE html>
<html>
    <head>
        <meta charset="utf-8" />
        <meta name="format-detection" content="telephone=no" />
        <!-- WARNING: for iOS 7, remove the width=device-width and height=device-height attributes. See https://issues.apache.org/jira/browse/CB-4323 -->
        <meta name="viewport" content="user-scalable=no, initial-scale=1, maximum-scale=1, minimum-scale=1, width=device-width, height=device-height, target-densitydpi=device-dpi" />
        <link rel="stylesheet" type="text/css" href="css/index.css" />
        <title>Assets Picker Plugin</title>
    </head>
    <body>
        <div class="app">
            <h1>Apache Cordova</h1>
            <div id="deviceready" class="blink">
                <img id="overlay" src="img/overlay.png"></img>
                <p class="event listening">Connecting to Device</p>
                <p class="event received">Device is Ready</p>
                
            </div>
        </div>
        <div style="position:absolute;left:0%;top:0%">
            <table id="imagetable">
            </table>
        </div>
        <div style="position:absolute;left:20%;top:20%">
            <input type="button" value="Pick" onclick="onPick()" style="width:100px;height:30px"/>
            <input type="button" value="Clear" onclick="onClear()" style="width:100px;height:30px"/>
            <input type="button" value="Map" onclick="onMap()" style="width:100px;height:30px"/>
        </div>
        <div style="position:absolute;left:20%;top:30%">
            <input type="radio" value="0" id="normal" name="type" onclick="onNormalBookmarkClicked()" checked/>
            <label for="normal" value="Normal Bookmarks" >Normal Bookmarks </label> <br>
            <input type="radio" value="1" id="date" name="type" onclick="onDateBookmarkClicked()"/>
            <label for="date" value="Date Bookmarks">Date Bookmarks </label>
        </div>
        <script type="text/javascript" src="cordova.js"></script>
        <script type="text/javascript" src="js/index.js"></script>
        <script type="text/javascript">
            app.initialize();
            </script>
        <script type="text/javascript">
            var selectedAssets = new Array();
            var isFileUri = true; // get uri or data
            
            var isResize = true; // use resize feature or not
            var targetWidth = 640;
            var targetHeight = 640;
            
            var isUseGetById = false; // call getById to get picture data or access directly
            var isResizeOnGetById = false;
            
            var previousAlbums = {};
            
            // called when "pick" button is clicked
            function onPick()
            {
                
                // set overlay icon
                if (document.getElementById("overlay"))
                {
                    var overlayIcon = getBase64Image(document.getElementById("overlay"));
                    window.plugin.snappi.assetspicker.setOverlay(Camera.Overlay.PREVIOUS_SELECTED, overlayIcon, function(){}, function(msg){alert("failure in setOverlay:" + msg);});
                }
                
                var assetsUuidExt = new Array();
                if (selectedAssets != null && selectedAssets.length != 0)
                {
                    for (var i = 0; i < selectedAssets.length; i++)
                    {
                        assetsUuidExt[i] = selectedAssets[i].uuid + "." + selectedAssets[i].orig_ext;
                    }
                }
                var overlayObj = {};
                
                overlayObj[Camera.Overlay.PREVIOUS_SELECTED] = assetsUuidExt;
                
                
                
                var options = {
                    quality: 75,
                    
                    encodingType: Camera.EncodingType.JPEG,
                    overlay: overlayObj,
                    thumbnail: true,
                    popoverOptions: {
                        x : 300,
                        y : 200,
                        width : 40,
                        height : 20,
                        arrowDir : Camera.PopoverArrowDirection.ARROW_ANY,
			popoverWidth : 500,
			popoverHeight : 500
                    }
                };
                if (isFileUri == true)
                options.destinationType = Camera.DestinationType.FILE_URI;
                else
                options.destinationType = Camera.DestinationType.DATA_URL;
                if (isResize == true)
                {
                    options.targetWidth = targetWidth;
                    options.targetHeight = targetHeight;
                }
                
                options.bookmarks = previousAlbums;
                
                window.plugin.snappi.assetspicker.getPicture(onSuccess, onCancel, options);
            }
        
        // called when "clear" button is clicked
        function onClear()
        {
            selectedAssets = new Array();
            document.getElementById("imagetable").innerHTML = "";
        }
        
        // success callback
        function onSuccess(dataArray)
        {
            // get previous albums
            if (document.getElementById("normal").checked)
            {
                getPreviousAlbums();
            }
            
            
            selectedAssets = dataArray;
            var strTr = "";
            for (i = 0; i < selectedAssets.length; i++)
            {
                var obj = selectedAssets[i];
                strTr += "<tr><td><img id='" + obj.id + "' /></td><td>" + obj.exif.PixelXDimension + " x " + obj.exif.PixelYDimension + " : " + obj.exif.Orientation + "</td><td>" + obj.exif.DateTimeOriginal + "</td></tr>";
            }
            document.getElementById("imagetable").innerHTML = strTr;
            for (i = 0; i < selectedAssets.length; i++)
            {
                var obj = selectedAssets[i];
                
                var image = document.getElementById(obj.id);
                if (isFileUri)
                {
                    if (isUseGetById)
                    {
                        var options = {
                            quality: 75,
                            destinationType: Camera.DestinationType.DATA_URL,
                            encodingType: Camera.EncodingType.JPEG
                        };
                        
                        if (isResizeOnGetById == true)
                        {
                            options.targetWidth = targetWidth;
                            options.targetHeight = targetHeight;
                        }
                        window.plugin.snappi.assetspicker.getById(obj.uuid, obj.orig_ext, onGetById, onCancel, options);
                    }
                    else
                    image.src = obj.data;
                    
                }
                else
                image.src = "data:image/jpeg;base64," + obj.data;
            }
        }
        
        // cancel callback
        function onCancel(message)
        {
            // get previous albums
            if (document.getElementById("normal").checked)
            {
                getPreviousAlbums();
            }
            //alert(message);
        }
        
        // getById success callback
        function onGetById(data)
        {
            var image = document.getElementById(data.id);
            image.src = "data:image/jpeg;base64," + data.data;
        }
        
        function getBase64Image(img)
        {
            // Create an empty canvas element
            var canvas = document.createElement("canvas");
            canvas.width = img.width;
            canvas.height = img.height;
            
            // Copy the image contents to the canvas
            var ctx = canvas.getContext("2d");
            ctx.drawImage(img, 0, 0);
            
            // Get the data-URL formatted image
            // Firefox supports PNG and JPEG. You could check img.src to
            // guess the original format, but be aware the using "image/jpg"
            // will re-encode the image.
            var dataURL = canvas.toDataURL("image/png");
            
            return dataURL.replace(/^data:image\/(png|jpg);base64,/, "");
        }
        
        function onNormalBookmarkClicked()
        {
            // get previous albums
            getPreviousAlbums();
        }
        
        function getPreviousAlbums()
        {
            // get previous albums
            window.plugin.snappi.assetspicker.getPreviousAlbums(onGetPreviousAlbumsSuccess, onGetPreviousAlbumsFailure);
        }
        
        function onGetPreviousAlbumsFailure(msg)
        {
            alert(msg);
        }
        
        function onGetPreviousAlbumsSuccess(result)
        {
            previousAlbums = result;
        }
        
        function onDateBookmarkClicked()
        {
            previousAlbums = { "date" : ["2014-04-04", "2014-06-03", "2014-06-04", "2014-06-05"]};
        }
        
        function onMap()
        {
            options = {
                pluck:["DateTimeOriginal"],
                fromDate:"2014-04-04T12:03:24.234Z",
                toDate:"2014-06-04T03:12:35.523Z"};
            window.plugin.snappi.assetspicker.mapAssetsLibrary(onMapSuccess, onMapFailed, options);
        }
        
        function onMapSuccess(mapped)
        {
            alert(mapped.lastDate + ",  count : " + mapped.assets.length);
        }
        
        function onMapFailed(message)
        {
            //
        }
        
            </script>    </body>
</html>
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request


## License

This software is released under the [Apache 2.0 License][apache2_license].

© 2013-2014 Snaphappi, Inc. All rights reserved

[ctassetspickercontroller]: https://github.com/chiunam/CTAssetsPickerController
[cordova-plugin-local-notifications]: https://github.com/katzer/cordova-plugin-local-notifications
[cordova]: https://cordova.apache.org
[PGB_plugin]: https://build.phonegap.com/plugins/413
[onsuccess]: #onSuccess
[oncancel]: #onCancel
[options]: #options
[getById]: #getById
[ongetbyid]: #onGetById
[CLI]: http://cordova.apache.org/docs/en/3.0.0/guide_cli_index.md.html#The%20Command-line%20Interface
[PGB]: http://docs.build.phonegap.com/en_US/3.3.0/index.html
[apache2_license]: http://opensource.org/licenses/Apache-2.0
