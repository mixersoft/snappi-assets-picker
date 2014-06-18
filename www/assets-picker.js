/**
 Camera Options
 { quality : 75,
 destinationType : Camera.DestinationType.DATA_URL,
 sourceType : Camera.PictureSourceType.CAMERA,
 allowEdit : true,
 encodingType: Camera.EncodingType.JPEG,
 targetWidth: 100,
 targetHeight: 100,
 popoverOptions: CameraPopoverOptions,
 saveToPhotoAlbum: false
 overlay: {name: arryofIds},
 scrollToDate: currDate
 };
 */

cordova.define("cordova/plugin/AssetsPickerPlugin", function(require, exports, module) {
               
               var exec = require('cordova/exec');
               var AssetsPickerPlugin = function(){};
               
               AssetsPickerPlugin.prototype.getPicture = function(success, failure, options) {
               exec(success, failure, "CAssetsPickerPlugin", "getPicture", [options]);
               };
               
               AssetsPickerPlugin.prototype.getById = function(uuid, orig_ext, success, failure, options) {
               if (arguments.length == 5)
               exec(success, failure, "CAssetsPickerPlugin", "getById", [uuid, orig_ext, options]);
               else
               exec(orig_ext, success, "CAssetsPickerPlugin", "getById", [uuid, "JPG", failure]);
               };
               
               AssetsPickerPlugin.prototype.setOverlay = function(overlayName, iconData, success, failure)
               {
               if (arguments.length == 2)
               exec(function(){}, function(msg){}, "CAssetsPickerPlugin", "setOverlay", [overlayName, iconData]);
               else if (arguments.length == 3)
               exec(success, function(msg){}, "CAssetsPickerPlugin", "setOverlay", [overlayName, iconData]);
               else if (arguments.length == 4)
               exec(success, failure, "CAssetsPickerPlugin", "setOverlay", [overlayName, iconData]);
               };
               
               AssetsPickerPlugin.prototype.getPreviousAlbums = function(success, failure) {
                exec(success, failure, "CAssetsPickerPlugin", "getPreviousAlbums", []);
               };
               
		AssetsPickerPlugin.prototype.mapAssetsLibrary = function(success, failure, options) {
               exec(success, failure, "CAssetsPickerPlugin", "mapAssetsLibrary", [options]);
               }

               var myplugin = new AssetsPickerPlugin();
               
               module.exports = myplugin;
               
               });

var AssetsPickerPlugin = cordova.require("cordova/plugin/AssetsPickerPlugin");

// define constants
var DestinationType = {
    DATA_URL : 0,
    FILE_URI : 1
};

var PictureSourceType = {
    PHOTOLIBRARY : 0,
    CAMERA : 1,
    SAVEDPHOTOALBUM : 2
};

var EncodingType = {
    JPEG : 0,
    PNG : 1
};

var MediaType = {
    PICTURE : 0,
    VIDEO : 1,
    ALLMEDIA : 2
};

var PopoverArrowDirection = {
    ARROW_UP : 1,
    ARROW_DOWN : 2,
    ARROW_LEFT : 4,
    ARROW_RIGHT : 8,
    ARROW_ANY : 15
};
   
var Overlay = {
    PREVIOUS_SELECTED : "previousSelected",
    OVERLAY_SPECIAL : "overlaySpecial"
};

AssetsPickerPlugin.DestinationType = DestinationType;
AssetsPickerPlugin.PictureSourceType = PictureSourceType;
AssetsPickerPlugin.EncodingType = EncodingType;
AssetsPickerPlugin.MediaType = MediaType;
AssetsPickerPlugin.PopoverArrowDirection = PopoverArrowDirection;
AssetsPickerPlugin.Overlay = Overlay;

module.exports = AssetsPickerPlugin;