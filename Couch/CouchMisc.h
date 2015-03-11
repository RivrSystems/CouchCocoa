//
//  CouchMisc.h
//  CouchCocoa
//
//  Created by Jens Alfke on 1/13/12.
//  Copyright (c) 2012 Couchbase, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

// STOLEN FROM TD_Body.h
/** Database sequence ID */
typedef SInt64 SequenceNumber;

// hopefully not required if we're just using the change tracker parts of TouchDB-iOS
//#import <TouchDB/Couch_Revision.h>

extern NSString* const CouchHTTPErrorDomain;

NSString* CouchCreateUUID( void );

NSData* CouchSHA1Digest( NSData* input );
NSData* CouchSHA256Digest( NSData* input );

NSString* CouchHexSHA1Digest( NSData* input );

NSData* CouchHMACSHA1(NSData* key, NSData* data);
NSData* CouchHMACSHA256(NSData* key, NSData* data);

/** Generates a hex dump of a sequence of bytes.
 The result is lowercase. This is important for CouchDB compatibility. */
NSString* CouchHexFromBytes( const void* bytes, size_t length);

NSComparisonResult CouchSequenceCompare( SequenceNumber a, SequenceNumber b);

/** Escapes a document or revision ID for use in a URL.
 This does the usual %-escaping, but makes sure that '/' is escaped in case the ID appears in the path portion of the URL, and that '&' is escaped in case the ID appears in a query value. */
NSString* CouchEscapeID( NSString* param );

/** Escapes a string to be used as the value of a query parameter in a URL.
 This does the usual %-escaping, but makes sure that '&' is also escaped. */
NSString* CouchEscapeURLParam( NSString* param );

/** Wraps a string in double-quotes and prepends backslashes to any existing double-quote or backslash characters in it. */
NSString* CouchQuoteString( NSString* param );

/** Undoes effect of CouchQuoteString, i.e. removes backslash escapes and any surrounding double-quotes.
 If the string has no surrounding double-quotes it will be returned as-is. */
NSString* CouchUnquoteString( NSString* param );

/** Returns YES if this error appears to be due to the computer being offline or the remote host being unreachable. */
BOOL CouchIsOfflineError( NSError* error );

/** Returns YES if this is a network/HTTP error that is likely to be transient.
 Examples are timeout, connection lost, 502 Bad Gateway... */
BOOL CouchMayBeTransientError( NSError* error );

/** Returns YES if this error appears to be due to a creating a file/dir that already exists. */
BOOL CouchIsFileExistsError( NSError* error );

/** Returns the input URL without the query string or fragment identifier, just ending with the path. */
NSURL* CouchURLWithoutQuery( NSURL* url );

/** Appends path components to a URL. These will NOT be URL-escaped, so you can include queries. */
NSURL* CouchAppendToURL(NSURL* baseURL, NSString* toAppend);