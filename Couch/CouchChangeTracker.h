//
//  CouchChangeTracker.h
//  CouchCocoa
//
//  Created by Jens Alfke on 6/20/11.
//  Copyright 2011 Couchbase, Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file
//  except in compliance with the License. You may obtain a copy of the License at
//    http://www.apache.org/licenses/LICENSE-2.0
//  Unless required by applicable law or agreed to in writing, software distributed under the
//  License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
//  either express or implied. See the License for the specific language governing permissions
//  and limitations under the License.

#import <Foundation/Foundation.h>
@class CouchChangeTracker;
@protocol CouchAuthorizer;


@protocol CouchChangeTrackerClient <NSObject>
@optional
- (void) changeTrackerReceivedChange: (NSDictionary*)change;
- (void) changeTrackerReceivedChanges: (NSArray*)changes;
- (void) changeTrackerStopped: (CouchChangeTracker*)tracker;
@end


typedef enum CouchChangeTrackerMode {
    kOneShot,
    kLongPoll,
    kContinuous
} CouchChangeTrackerMode;


/** Reads the continuous-mode _changes feed of a database, and sends the individual change entries to its client.  */
@interface CouchChangeTracker : NSObject <NSStreamDelegate>
{
    @protected
    NSURL* _databaseURL;
    id<CouchChangeTrackerClient> __weak _client;
    CouchChangeTrackerMode _mode;
    id _lastSequenceID;
    unsigned _limit;
    NSError* _error;
    BOOL _includeConflicts;
    NSString* _filterName;
    NSDictionary* _filterParameters;
    NSTimeInterval _heartbeat;
    NSDictionary* _requestHeaders;
    id<CouchAuthorizer> _authorizer;
    unsigned _retryCount;
}

- (id)initWithDatabaseURL: (NSURL*)databaseURL
                     mode: (CouchChangeTrackerMode)mode
                conflicts: (BOOL)includeConflicts
             lastSequence: (id)lastSequenceID
                   client: (id<CouchChangeTrackerClient>)client;

@property (readonly, nonatomic) NSURL* databaseURL;
@property (readonly, nonatomic) NSString* databaseName;
@property (readonly) NSURL* changesFeedURL;
@property (readonly, copy, nonatomic) id lastSequenceID;
@property (strong, nonatomic) NSError* error;
@property (weak, nonatomic) id<CouchChangeTrackerClient> client;
@property (strong, nonatomic) NSDictionary *requestHeaders;
@property (strong, nonatomic) id<CouchAuthorizer> authorizer;

@property (nonatomic) CouchChangeTrackerMode mode;
@property (copy) NSString* filterName;
@property (copy) NSDictionary* filterParameters;
@property (nonatomic) unsigned limit;
@property (nonatomic) NSTimeInterval heartbeat;
@property (nonatomic) NSArray *docIDs;

- (BOOL) start;
- (void) stop;

/** Asks the tracker to retry connecting, _if_ it's currently disconnected but waiting to retry.
 This should be called when the reachability of the remote host changes, or when the
 app is reactivated. */
- (void) retry;

// Protected
@property (readonly) NSString* changesFeedPath;
- (void) setUpstreamError: (NSString*)message;
- (void) failedWithError: (NSError*)error;
- (NSInteger) receivedPollResponse: (NSData*)body errorMessage: (NSString**)errorMessage;
- (BOOL) receivedChanges: (NSArray*)changes errorMessage: (NSString**)errorMessage;
- (BOOL) receivedChange: (NSDictionary*)change;
- (void) stopped; // override this

@end
