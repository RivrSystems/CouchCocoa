//
//  RESTBody.m
//  CouchCocoa
//
//  Created by Jens Alfke on 5/28/11.
//  Copyright 2011 Couchbase, Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file
//  except in compliance with the License. You may obtain a copy of the License at
//    http://www.apache.org/licenses/LICENSE-2.0
//  Unless required by applicable law or agreed to in writing, software distributed under the
//  License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
//  either express or implied. See the License for the specific language governing permissions
//  and limitations under the License.

#import "RESTBody.h"

#import "RESTInternal.h"
#import "RESTBase64.h"


@implementation RESTBody


@synthesize content = _content, headers = _headers, resource = _resource;


+ (NSDictionary*) entityHeadersFrom: (NSDictionary*)headers {
    static NSSet* kEntityHeaderNames;
    if (!kEntityHeaderNames) {
        // "HTTP: The Definitive Guide", pp.72-73
        kEntityHeaderNames = [[NSSet alloc] initWithObjects:
                              @"Allow", @"Location",
                              @"Content-Base", @"Content-Encoding", @"Content-Language",
                              @"Content-Length", @"Content-Location", @"Content-MD5",
                              @"Content-Range", @"Content-Type",
                              @"Etag", @"Expires", @"Last-Modified", nil];
    }
    
    NSMutableDictionary* entityHeaders = [NSMutableDictionary dictionary];
    for (NSString* headerName in headers) {
        if ([kEntityHeaderNames containsObject: headerName]) {
            [entityHeaders setObject: [headers objectForKey: headerName]
                              forKey: headerName];
        }
    }
    return (entityHeaders.count < headers.count) ? entityHeaders : headers;
}


// This is overridden by RESTMutableBody to make _headers a mutable copy.
- (void) setHeaders:(NSDictionary *)headers {
    if (headers != _headers) {
        _headers = [headers copy];
    }
}


- (id)init {
    self = [super init];
    if (self) {
        _content = [[NSData alloc] init];
        [self setHeaders: [NSDictionary dictionary]];
    }
    return self;
}


- (id) initWithContent: (NSData*)content 
               headers: (NSDictionary*)headers
              resource: (RESTResource*)resource
{
    NSParameterAssert(content);
    NSParameterAssert(headers);
    self = [super init];
    if (self) {
        _content = [content copy];
        [self setHeaders: headers];
    }
    return self;
}


- (id) initWithData: (NSData*)content contentType: (NSString*)contentType {
    return [self initWithContent: content
                         headers: [NSDictionary dictionaryWithObject: contentType
                                                              forKey: @"Content-Type"]
                        resource: nil];
}




- (id) copyWithZone:(NSZone *)zone {
    return self;
}


- (id) mutableCopyWithZone:(NSZone *)zone {
    return [[RESTMutableBody alloc] initWithContent: _content
                                            headers: _headers
                                           resource: _resource];
}


- (BOOL) isEqual:(id)object {
    if (object == self)
        return YES;
    if (![object isKindOfClass: [RESTBody class]])
        return NO;
    return [_content isEqual: [object content]] && [_headers isEqual: [object headers]];
}

- (NSUInteger) hash {
    return _content.hash ^ _headers.hash;
}


- (NSString*) contentType   {return [_headers objectForKey:@"Content-Type"];}
- (NSString*) eTag          {return [_headers objectForKey:@"Etag"];}
- (NSString*) lastModified  {return [_headers objectForKey:@"Last-Modified"];}


- (NSString*) asString {
    NSStringEncoding encoding = NSUTF8StringEncoding;   //FIX: Get from _response.textEncodingName
    return [[NSString alloc] initWithData: _content encoding: encoding];
}


- (id) fromJSON {
    if (!_fromJSON)
        _fromJSON = [[RESTBody JSONObjectWithData: _content] copy];
    return _fromJSON;
}


@end




@implementation RESTMutableBody


- (NSData*) content {
    return _content;
}

- (void) setContent:(NSData *)content {
    if (content != _content) {
        _content = [content copy];
        _fromJSON = nil;
    }
}


- (NSDictionary*) headers {
    return [_headers copy];
}


- (void) setHeaders:(NSDictionary *)headers {
    if (headers != _headers) {
        _headers = [headers mutableCopy];
    }
}


- (NSMutableDictionary*) mutableHeaders {
    return (NSMutableDictionary*)_headers;
}


- (void) setMutableHeaders: (NSMutableDictionary*)headers {
    [self setHeaders: headers];
}


- (id) copyWithZone:(NSZone *)zone {
    return [[RESTBody alloc] initWithContent: _content headers: _headers resource: _resource];
}


- (NSString*) contentType   {return [_headers objectForKey:@"Content-Type"];}

- (void) setContentType: (NSString*)contentType {
    [self.mutableHeaders setObject: contentType forKey: @"Content-Type"];
}


- (RESTResource*) resource {
    return _resource;
}

- (void) setResource:(RESTResource *)resource {
    if (resource != _resource) {
        _resource = resource;
    }
}


@end


#pragma mark JSON:

#if (MAC_OS_X_VERSION_MAX_ALLOWED < 1070 || (defined(__IPHONE_OS_VERSION_MAX_ALLOWED) &&  __IPHONE_OS_VERSION_MAX_ALLOWED < 50000))
// Building against earlier SDK that doesn't contain NSJSONSerialization.h.
// So declare the necessary bits here (copied from the 10.7 SDK):
enum {
    NSJSONReadingMutableContainers = (1UL << 0),
    NSJSONReadingMutableLeaves = (1UL << 1),
    NSJSONReadingAllowFragments = (1UL << 2),
    NSJSONWritingPrettyPrinted = (1UL << 0)
};
@interface NSJSONSerialization : NSObject
+ (NSData *)dataWithJSONObject:(id)obj options:(NSUInteger)opt error:(NSError **)error;
+ (id)JSONObjectWithData:(NSData *)data options:(NSUInteger)opt error:(NSError **)error;
@end
#endif


@implementation RESTBody (JSON)

#define sJSONSerialization NSJSONSerialization


+ (NSData*) dataWithJSONObject: (id)obj {
    return [sJSONSerialization dataWithJSONObject: obj 
                                          options: 0
                                            error: NULL];
}

+ (NSString*) stringWithJSONObject: (id)obj {
    NSData* data = [sJSONSerialization dataWithJSONObject: obj                                               
                                                  options: 0
                                                    error: NULL];
    if (!data)
        return nil;
    return [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
}

+ (NSString*) prettyStringWithJSONObject: (id)obj {
    NSData* data = [sJSONSerialization dataWithJSONObject: obj                                               
                                                  options: NSJSONReadingAllowFragments
                                                            | NSJSONWritingPrettyPrinted
                                                    error: NULL];
    if (!data)
        return nil;
    return [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
}


+ (id) JSONObjectWithData: (NSData*)data {
    return [sJSONSerialization JSONObjectWithData: data 
                                          options: 0
                                            error: NULL];
}

+ (id) JSONObjectWithString: (NSString*)string {
    NSData* data = [string dataUsingEncoding: NSUTF8StringEncoding];
    return [sJSONSerialization JSONObjectWithData: data 
                                          options: 0
                                            error: NULL];
}


// This function is not thread-safe, nor is the NSDateFormatter instance it returns.
// Make sure that this function and the formatter are called on only one thread at a time.
static NSDateFormatter* getISO8601Formatter() {
    static NSDateFormatter* sFormatter;
    if (!sFormatter) {
        // Thanks to DenNukem's answer in http://stackoverflow.com/questions/399527/
        sFormatter = [[NSDateFormatter alloc] init];
        sFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss'Z'";
        sFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
        sFormatter.calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
        sFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    }
    return sFormatter;
}


+ (NSString*) JSONObjectWithDate: (NSDate*)date {
    if (!date)
        return nil;
    @synchronized(self) {
        return [getISO8601Formatter() stringFromDate: date];
    }
}

+ (NSDate*) dateWithJSONObject: (id)jsonObject {
    NSString* string = $castIf(NSString, jsonObject);
    if (!string)
        return nil;
    @synchronized(self) {
        return [getISO8601Formatter() dateFromString: string];
    }
}


+ (NSString*) base64WithData: (NSData*)data {
    return [RESTBase64 encode: data];
}


+ (NSData*) dataWithBase64: (NSString*)base64 {
    return [RESTBase64 decode: base64];
}


@end