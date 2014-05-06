//
//  URLParser.h
//  TestPlugin
//
//  Created by Donald Pae on 5/6/14.
//
//

#import <Foundation/Foundation.h>

@interface URLParser : NSObject


+ (URLParser *)parserWithURL:(NSURL *)url;

- (id)valueForKey:(NSString *)key;

@end
