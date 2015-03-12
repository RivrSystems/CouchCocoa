//
//  CouchJSON.h
//  CouchCocoa
//
//  Created by Jens Alfke on 2/27/12.
//  Copyright (c) 2012 Couchbase, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

/** Identical to the corresponding NSJSON option flags. */
enum {
    CouchJSONReadingMutableContainers = (1UL << 0),
    CouchJSONReadingMutableLeaves = (1UL << 1),
    CouchJSONReadingAllowFragments = (1UL << 2)
};
typedef NSUInteger CouchJSONReadingOptions;

/** Identical to the corresponding NSJSON option flags. */
enum {
    CouchJSONWritingPrettyPrinted = (1UL << 0),
    
    CouchJSONWritingAllowFragments = (1UL << 23)           // This one I made up
};
typedef NSUInteger CouchJSONWritingOptions;


@interface CouchJSON : NSJSONSerialization
@end


@interface CouchJSON (Extensions)
/** Same as -dataWithJSONObject... but returns an NSString. */
+ (NSString*) stringWithJSONObject:(id)obj
                           options:(CouchJSONWritingOptions)opt
                             error:(NSError **)error;

/** Given valid JSON data representing a dictionary, inserts the contents of the given NSDictionary into it and returns the resulting JSON data.
 This does not parse or regenerate the JSON, so it's quite fast.
 But it will generate invalid JSON if the input JSON begins or ends with whitespace, or if the dictionary contains any keys that are already in the original JSON. */
+ (NSData*) appendDictionary: (NSDictionary*)dict
        toJSONDictionaryData: (NSData*)json;
@end


/** Wrapper for an NSArray of JSON data, that avoids having to parse the data if it's not used.
 NSData objects in the array will be parsed into native objects before being returned to the caller from -objectAtIndex. */
@interface CouchLazyArrayOfJSON : NSArray
{
    NSMutableArray* _array;
}
- (id) initWithArray: (NSMutableArray*)array;
@end