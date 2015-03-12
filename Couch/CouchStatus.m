//
//  CouchStatus.m
//  CouchCocoa
//
//  Created by Jens Alfke on 4/6/12.
//  Copyright (c) 2012 Couchbase, Inc. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file
//  except in compliance with the License. You may obtain a copy of the License at
//    http://www.apache.org/licenses/LICENSE-2.0
//  Unless required by applicable law or agreed to in writing, software distributed under the
//  License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
//  either express or implied. See the License for the specific language governing permissions
//  and limitations under the License.

#import "CouchStatus.h"
#import "RESTOperation.h"


struct StatusMapEntry {
    CouchStatus status;
    int httpStatus;
    const char* message;
};

static const struct StatusMapEntry kStatusMap[] = {
    // For compatibility with CouchDB, return the same strings it does (see couch_httpd.erl)
    {kCouchStatusBadRequest,           400, "bad_request"},
    {kCouchStatusUnauthorized,         401, "unauthorized"},
    {kCouchStatusNotFound,             404, "not_found"},
    {kCouchStatusForbidden,            403, "forbidden"},
    {kCouchStatusNotAcceptable,        406, "not_acceptable"},
    {kCouchStatusConflict,             409, "conflict"},
    {kCouchStatusDuplicate,            412, "file_exists"},      // really 'Precondition Failed'
    {kCouchStatusUnsupportedType,      415, "bad_content_type"},
    
    // These are nonstandard status codes; map them to closest HTTP equivalents:
    {kCouchStatusBadEncoding,          400, "Bad data encoding"},
    {kCouchStatusBadAttachment,        400, "Invalid attachment"},
    {kCouchStatusAttachmentNotFound,   404, "Attachment not found"},
    {kCouchStatusBadJSON,              400, "Invalid JSON"},
    {kCouchStatusBadID,                400, "Invalid database/document/revision ID"},
    {kCouchStatusBadParam,             400, "Invalid parameter in JSON body"},
    {kCouchStatusDeleted,              404, "deleted"},
    
    {kCouchStatusUpstreamError,        502, "Invalid response from remote replication server"},
    {kCouchStatusDBError,              500, "Database error!"},
    {kCouchStatusCorruptError,         500, "Invalid data in database"},
    {kCouchStatusAttachmentError,      500, "Attachment store error"},
    {kCouchStatusCallbackError,        500, "Application callback block failed"},
    {kCouchStatusException,            500, "Internal error"},
};


int CouchStatusToHTTPStatus( CouchStatus status, NSString** outMessage ) {
    for (unsigned i=0; i < sizeof(kStatusMap)/sizeof(kStatusMap[0]); ++i) {
        if (kStatusMap[i].status == status) {
            if (outMessage)
                *outMessage = [NSString stringWithUTF8String: kStatusMap[i].message];
            return kStatusMap[i].httpStatus;
        }
    }
    if (outMessage)
        *outMessage = [NSHTTPURLResponse localizedStringForStatusCode: status];
    return status;
}


NSError* CouchStatusToNSErrorWithInfo( CouchStatus status, NSURL* url, NSDictionary* extraInfo ) {
    NSString* reason;
    int httpStatus = CouchStatusToHTTPStatus(status, &reason);
    NSMutableDictionary* info = $mdict({NSURLErrorKey, url},
                                       {NSLocalizedFailureReasonErrorKey, reason},
                                       {NSLocalizedDescriptionKey, $sprintf(@"%i %@", httpStatus, reason)});
    if (extraInfo)
        [info addEntriesFromDictionary: extraInfo];
    return [NSError errorWithDomain: CouchHTTPErrorDomain code: status userInfo: [info copy]];
}


NSError* CouchStatusToNSError( CouchStatus status, NSURL* url ) {
    return CouchStatusToNSErrorWithInfo(status, url, nil);
}