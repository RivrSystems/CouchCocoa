//
//  CouchRemoteRequest.h
//  CouchCocoa
//
//  Created by Jens Alfke on 12/15/11.
//  Copyright (c) 2011 Couchbase, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol CouchAuthorizer;


/** The signature of the completion block called by a CouchRemoteRequest.
 @param result  On success, a 'result' object; by default this is the CouchRemoteRequest iself, but subclasses may return something else. On failure, this will likely be nil.
 @param error  The error, if any, else nil. */
typedef void (^CouchRemoteRequestCompletionBlock)(id result, NSError* error);


/** Asynchronous HTTP request; a fairly simple wrapper around NSURLConnection that calls a completion block when ready. */
@interface CouchRemoteRequest : NSObject <NSURLConnectionDelegate
#if TARGET_OS_IPHONE || defined(__MAC_10_8)
, NSURLConnectionDataDelegate
#endif
>
{
@protected
    NSMutableURLRequest* _request;
    id<CouchAuthorizer> _authorizer;
    CouchRemoteRequestCompletionBlock _onCompletion;
    NSURLConnection* _connection;
    int _status;
    UInt8 _retryCount;
    bool _dontLog404;
    bool _challenged;
}

/** Creates a request; call -start to send it on its way. */
- (id) initWithMethod: (NSString*)method
                  URL: (NSURL*)url
                 body: (id)body
       requestHeaders: (NSDictionary *)requestHeaders
         onCompletion: (CouchRemoteRequestCompletionBlock)onCompletion;

@property NSTimeInterval timeoutInterval;
@property (strong, nonatomic) id<CouchAuthorizer>authorizer;

/** In some cases a kCouchStatusNotFound Not Found is an expected condition and shouldn't be logged; call this to suppress that log message. */
- (void) dontLog404;

/** Starts a request; when finished, the onCompletion block will be called. */
- (void) start;

/** Stops the request, calling the onCompletion block. */
- (void) stop;

/** JSON-compatible dictionary with status information, to be returned from _activity API */
@property (readonly) NSMutableDictionary* statusInfo;

// protected:
- (void) setupRequest: (NSMutableURLRequest*)request withBody: (id)body;
- (void) clearConnection;
- (void) cancelWithStatus: (int)status;
- (void) respondWithResult: (id)result error: (NSError*)error;

// The value to use for the User-Agent HTTP header.
+ (NSString*) userAgentHeader;

// Shared subroutines to handle NSURLAuthenticationMethodServerTrust challenges
+ (BOOL) checkTrust: (SecTrustRef)trust forHost: (NSString*)host;

@end


/** A request that parses its response body as JSON.
 The parsed object will be returned as the first parameter of the completion block. */
@interface CouchRemoteJSONRequest : CouchRemoteRequest
{
@private
    NSMutableData* _jsonBuffer;
}
@end