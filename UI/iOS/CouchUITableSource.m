//
//  CouchUITableSource.m
//  CouchCocoa
//
//  Created by Jens Alfke on 8/2/11.
//  Copyright 2011 Couchbase, Inc. All rights reserved.
//

#import "CouchUITableSource.h"
#import "CouchInternal.h"


@interface CouchUITableSource ()
{
    @private
    UITableView* _tableView;
    CouchLiveQuery* _query;
	NSMutableArray* _rows;
    NSString* _labelProperty;
    BOOL _deletionAllowed;
}
@end


@implementation CouchUITableSource


- (id)init {
    self = [super init];
    if (self) {
        _deletionAllowed = YES;
    }
    return self;
}


- (void)dealloc {
    [_query removeObserver: self forKeyPath: @"rows"];
}


#pragma mark -
#pragma mark ACCESSORS:


@synthesize tableView=_tableView;
@synthesize rows=_rows;


- (CouchQueryRow*) rowAtIndex: (NSUInteger)index {
    return [_rows objectAtIndex: index];
}


- (NSIndexPath*) indexPathForDocument: (CouchDocument*)document {
    NSString* documentID = document.documentID;
    NSUInteger index = 0;
    for (CouchQueryRow* row in _rows) {
        if ([row.documentID isEqualToString: documentID])
            return [NSIndexPath indexPathForRow: index inSection: 0];
        ++index;
    }
    return nil;
}


- (CouchDocument*) documentAtIndexPath: (NSIndexPath*)path {
    if (path.section == 0)
        return [[_rows objectAtIndex: path.row] document];
    return nil;
}


#pragma mark -
#pragma mark QUERY HANDLING:


- (CouchLiveQuery*) query {
    return _query;
}

- (void) setQuery:(CouchLiveQuery *)query {
    if (query != _query) {
        [_query removeObserver: self forKeyPath: @"rows"];
        _query = query;
        [_query addObserver: self forKeyPath: @"rows" options: 0 context: NULL];
        [self reloadFromQuery];
    }
}


-(void) reloadFromQuery {
    CouchQueryEnumerator* rowEnum = _query.rows;
    if (rowEnum) {
        NSArray *oldRows = _rows;
        _rows = [rowEnum.allObjects mutableCopy];
        
        if (_tableView.delegate && [_tableView.delegate respondsToSelector:@selector(couchTableSource:willUpdateFromQuery:)]) {
            id<CouchUITableDelegate> delegate = (id<CouchUITableDelegate>)_tableView.delegate;
            [delegate couchTableSource:self willUpdateFromQuery:_query];
        }
        
        id delegate = _tableView.delegate;
        SEL selector = @selector(couchTableSource:updateFromQuery:previousRows:);
        if ([delegate respondsToSelector: selector]) {
            [delegate couchTableSource: self 
                       updateFromQuery: _query
                          previousRows: oldRows];
        } else {
            [self.tableView reloadData];
        }
    }
}


- (void) observeValueForKeyPath: (NSString*)keyPath ofObject: (id)object
                         change: (NSDictionary*)change context: (void*)context 
{
    if (object == _query)
        [self reloadFromQuery];
}


#pragma mark -
#pragma mark DATA SOURCE PROTOCOL:


@synthesize labelProperty=_labelProperty;


- (NSString*) labelForRow: (CouchQueryRow*)row {
    id value = row.value;
    if (_labelProperty) {
        if ([value isKindOfClass: [NSDictionary class]])
            value = [value objectForKey: _labelProperty];
        else
            value = nil;
        if (!value)
            value = [row.document propertyForKey: _labelProperty];
    }
    return [value description];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _rows.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Allow the delegate to create its own cell:
    UITableViewCell* cell;
    
    if (_tableView.delegate && [_tableView.delegate respondsToSelector:@selector(couchTableSource:cellForRowAtIndexPath:)]) {
        
        id<CouchUITableDelegate> delegate = (id<CouchUITableDelegate>)_tableView.delegate;
        cell = [delegate couchTableSource:self cellForRowAtIndexPath:indexPath];
    }
    
    if (!cell) {
        // ...if it doesn't, create a cell for it:
        cell = [tableView dequeueReusableCellWithIdentifier: @"CouchUITableDelegate"];
        if (!cell)
            cell = [[UITableViewCell alloc] initWithStyle: UITableViewCellStyleDefault
                                           reuseIdentifier: @"CouchUITableDelegate"];
        
        CouchQueryRow* row = [self rowAtIndex: indexPath.row];
        cell.textLabel.text = [self labelForRow: row];
        
        // Allow the delegate to customize the cell:
        id delegate = _tableView.delegate;
        if ([delegate respondsToSelector: @selector(couchTableSource:willUseCell:forRow:)])
            [(id<CouchUITableDelegate>)delegate couchTableSource: self willUseCell: cell forRow: row];
    }
    return cell;
}


#pragma mark -
#pragma mark EDITING:


@synthesize deletionAllowed=_deletionAllowed;


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return _deletionAllowed;
}


- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Queries have a sort order so reordering doesn't generally make sense.
    return NO;
}


- (void) checkDelete: (RESTOperation*)op {
    if (!op.isSuccessful) {
        // If the delete failed, undo the table row deletion by reloading from the db:
        
        if (_tableView.delegate && [_tableView.delegate
                                    respondsToSelector:@selector(couchTableSource:operationFailed:)]) {
            
            id<CouchUITableDelegate> delegate = (id<CouchUITableDelegate>)_tableView.delegate;
            [delegate couchTableSource:self operationFailed:op];
        }
        
        [self reloadFromQuery];
    }
}


- (void)tableView:(UITableView *)tableView
        commitEditingStyle:(UITableViewCellEditingStyle)editingStyle 
         forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the document from the database, asynchronously.
        RESTOperation* op = [[[self rowAtIndex:indexPath.row] document] DELETE];
        [op onCompletion: ^{ [self checkDelete: op]; }];
        [op start];
        
        // Delete the row from the table data source.
        [_rows removeObjectAtIndex:indexPath.row];
        [self.tableView deleteRowsAtIndexPaths: [NSArray arrayWithObject:indexPath]
                              withRowAnimation: UITableViewRowAnimationFade];
    }
}


- (void) deleteDocuments: (NSArray*)documents atIndexes: (NSArray*)indexPaths {
    RESTOperation* op = [_query.database deleteDocuments: documents];
    [op onCompletion: ^{ [self checkDelete: op]; }];
    
    NSMutableIndexSet* indexSet = [NSMutableIndexSet indexSet];
    for (NSIndexPath* path in indexPaths) {
        if (path.section == 0)
            [indexSet addIndex: path.row];
    }
    [_rows removeObjectsAtIndexes: indexSet];

    [_tableView deleteRowsAtIndexPaths: indexPaths withRowAnimation: UITableViewRowAnimationFade];
}


- (void) deleteDocumentsAtIndexes: (NSArray*)indexPaths {
    NSArray* docs = [indexPaths rest_map: ^(id path) {return [self documentAtIndexPath: path];}];
    [self deleteDocuments: docs atIndexes: indexPaths];
}


- (void) deleteDocuments: (NSArray*)documents {
    NSArray* paths = [documents rest_map: ^(id doc) {return [self indexPathForDocument: doc];}];
    [self deleteDocuments: documents atIndexes: paths];
}


@end
