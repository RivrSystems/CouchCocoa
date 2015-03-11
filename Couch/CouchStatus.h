//
//  CouchStatus.h
//  CouchCocoa
//
//  Created by Jens Alfke on 4/5/12.
//  Copyright (c) 2012 Couchbase, Inc. All rights reserved.
//


/** TouchDB internal status/error codes. Superset of HTTP status codes. */
typedef NS_ENUM(NSInteger, CouchStatus) {
    kCouchStatusOK             = 200,
    kCouchStatusCreated        = 201,
    kCouchStatusAccepted       = 206,
    
    kCouchStatusNotModified    = 304,
    
    kCouchStatusBadRequest     = 400,
    kCouchStatusUnauthorized   = 401,
    kCouchStatusForbidden      = 403,
    kCouchStatusNotFound       = 404,
    kCouchStatusNotAcceptable  = 406,
    kCouchStatusConflict       = 409,
    kCouchStatusDuplicate      = 412,      // Formally known as "Precondition Failed"
    kCouchStatusUnsupportedType= 415,
    
    kCouchStatusServerError    = 500,
    
    // Non-HTTP errors:
    kCouchStatusBadEncoding    = 490,
    kCouchStatusBadAttachment  = 491,
    kCouchStatusAttachmentNotFound = 492,
    kCouchStatusBadJSON        = 493,
    kCouchStatusBadID          = 494,
    kCouchStatusBadParam       = 495,
    kCouchStatusDeleted        = 496,      // Document deleted
    
    kCouchStatusUpstreamError  = 589,      // Error from remote replication server
    kCouchStatusDBError        = 590,      // SQLite error
    kCouchStatusCorruptError   = 591,      // bad data in database
    kCouchStatusAttachmentError= 592,      // problem with attachment store
    kCouchStatusCallbackError  = 593,      // app callback (emit fn, etc.) failed
    kCouchStatusException      = 594,      // Exception raised/caught
};


static inline bool CouchStatusIsError(CouchStatus status) {return status >= 300;}

int CouchStatusToHTTPStatus( CouchStatus status, NSString** outMessage );

NSError* CouchStatusToNSError( CouchStatus status, NSURL* url );
NSError* CouchStatusToNSErrorWithInfo( CouchStatus status, NSURL* url, NSDictionary* extraInfo );