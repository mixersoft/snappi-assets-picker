//
//  URLParser.m
//  TestPlugin
//
//  Created by Donald Pae on 5/6/14.
//
//

#import "URLParser.h"

@interface URLParser ()

@property(nonatomic, retain) NSURL *url;
@property(nonatomic, retain) NSMutableDictionary *queryStringDictionary;

@end

@implementation URLParser

- (id) init
{
    self = [super init];
    return self;
}

+ (URLParser *)parserWithURL:(NSURL *)url
{
    URLParser *parser = [[URLParser alloc] init];
    parser.url = url;
    parser.queryStringDictionary = [[NSMutableDictionary alloc] init];
    NSString *queryString = [url query];
    if (queryString)
    {
        NSArray *urlComponents = [queryString componentsSeparatedByString:@"&"];
        
        for (NSString *keyValuePair in urlComponents) {
            NSArray *pairComponents = [keyValuePair componentsSeparatedByString:@"="];
            NSString *key = [pairComponents objectAtIndex:0];
            NSString *value = [pairComponents objectAtIndex:1];
            
            [parser.queryStringDictionary setObject:value forKey:key];
        }
    }
    
    return parser;
}

- (id)valueForKey:(NSString *)key
{
    return [self.queryStringDictionary objectForKey:key];
}

@end
