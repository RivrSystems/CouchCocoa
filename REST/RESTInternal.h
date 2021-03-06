//
//  RESTInternal.h
//  CouchCocoa
//
//  Created by Jens Alfke on 6/25/11.
//  Copyright 2011 Couchbase, Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file
//  except in compliance with the License. You may obtain a copy of the License at
//    http://www.apache.org/licenses/LICENSE-2.0
//  Unless required by applicable law or agreed to in writing, software distributed under the
//  License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
//  either express or implied. See the License for the specific language governing permissions
//  and limitations under the License.

#import "REST.h"
#import "RESTCache.h"

void RESTWarn(NSString* format, ...) __attribute__((format(__NSString__, 1, 2)));;

extern BOOL gRESTWarnRaisesException;

id RESTCastIf(Class,id);
id RESTCastIfArrayOf(Class,id);

@interface RESTOperation ()
+ (NSError*) errorWithHTTPStatus: (int)httpStatus
                         message: (NSString*)message
                             URL: (NSURL*)url;
@property (nonatomic, readonly) UInt8 retryCount;
@end


@interface RESTResource ()
- (void) setURL: (NSURL*)url;
- (void) assignedRelativePath: (NSString*)relativePath;
@property (readwrite, strong) RESTCache* owningCache;
- (NSURLCredential*) credentialForOperation: (RESTOperation*)op;
- (NSURLProtectionSpace*) protectionSpaceForOperation: (RESTOperation*)op;
@end


@interface RESTCache ()
- (void) resourceBeingDealloced:(RESTResource*)resource;
@end


@interface NSArray (RESTExtensions)
- (NSArray*) rest_map: (id (^)(id obj))block;
@end