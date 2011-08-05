/*
 * Copyright (c) 2011 Todor Dimitrov
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 
 * Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 * 
 * Redistributions in binary form must reproduce the above copyright
 * notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution.
 * 
 * Neither the name of the project's author nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 */

#import "SparqlViewController.h"
#import "DefaultNamespaces.h"
#import <RestKit/RestKit.h>
#import "MainController.h"
#import "SparqlQuery.h"
#import "RDFTriple.h"
#import "DefaultNamespaces.h"
#import "URICache.h"
#import "NSTableView+TDExtensions.h"

@interface SparqlViewController() <RKObjectLoaderDelegate, NSTableViewDataSource, TDTableViewDelegate>

@property (nonatomic, retain) SparqlQuery *result;

@end


@implementation SparqlViewController {
    URICache *_uriCache;
}

@synthesize mainController=_mainController;
@synthesize queryString=_queryString;
@synthesize font=_font;
@synthesize resultsTable=_resultsTable;
@synthesize result=_result;

- (void)dealloc {
    [_queryString release], _queryString = nil;
    [_font release], _font = nil;
    [_result release], _result = nil;
    [_uriCache release], _uriCache = nil;
    [super dealloc];
}

- (void)awakeFromNib {
    self.font = [NSFont systemFontOfSize:10.0];
    [self populateNamespaces:self];
}

- (IBAction)performQuery:(id)sender {
    SparqlQuery *test = [[SparqlQuery alloc] init];
    test.query = self.queryString;
    
    RKObjectManager *objectManager = [RKObjectManager sharedManager];
    _mainController.processing = YES;
    [objectManager postObject:test delegate:self block:^(RKObjectLoader *loader) {
        loader.serializationMIMEType = RKMIMETypeJSON; // We want to send this request as JSON
        loader.targetObject = nil;  // Map the results back onto a new object instead of self
        // Set up a custom serialization mapping to handle this request
        loader.serializationMapping = [RKObjectMapping serializationMappingWithBlock:^(RKObjectMapping* mapping) {
            [mapping mapAttributes:@"query", nil];
        }];
        loader.serializationMapping.rootKeyPath = @"sparqlQuery";
    }];
    [test release];
}

- (IBAction)populateNamespaces:(id)sender {
    DefaultNamespaces *defaultNamespaces = [DefaultNamespaces sharedDefaultNamespaces];
    NSSet *namespaces = [defaultNamespaces namespaces];
    NSMutableString *preloadedPrefixes = [NSMutableString string];
    for (NSString *namespace in namespaces) {
        if ([namespace length] < 1) {
            continue;
        }
        NSString *prefix = [defaultNamespaces prefixForNamespace:namespace onlyEnabled:NO];
        if ([namespace length] < 1) {
            continue;
        }
        [preloadedPrefixes appendFormat:@"PREFIX %@: <%@>\n", prefix, namespace];
    }
    self.queryString = preloadedPrefixes;
}

- (void)populateResults {
    NSArray *columns = [NSArray arrayWithArray:[_resultsTable tableColumns]];
    for (NSTableColumn *column in columns) {
        [_resultsTable removeTableColumn:column];
    }
    if (!_result) {
        return;
    }
    for (NSString *variable in _result.variables) {
        NSTableColumn *varColumn = [[NSTableColumn alloc] initWithIdentifier:variable];
        [[varColumn headerCell] setStringValue:variable];
        [_resultsTable addTableColumn:varColumn];
        [varColumn release];
    }
    [_resultsTable reloadData];
}

#pragma mark -
#pragma mark RKObjectLoaderDelegate 
#pragma mark -

- (void)objectLoader:(RKObjectLoader *)objectLoader didFailWithError:(NSError *)error {
    _mainController.processing = NO;
    NSLog(@"An error occurred: %@", [error localizedDescription]);
    NSAlert *alert = [NSAlert alertWithError:error];
    [alert beginSheetModalForWindow:[NSApp mainWindow] modalDelegate:nil didEndSelector:nil contextInfo:NULL];
}

- (void)objectLoader:(RKObjectLoader *)objectLoader didLoadObject:(id)object {
    _mainController.processing = NO;
    if ([object isKindOfClass:[SparqlQuery class]]) {
        SparqlQuery *result = (SparqlQuery *)object;
        self.result = result;
        [_uriCache release];
        _uriCache = [[URICache alloc] initWithNamespaces:result.namespaces];
    } else if (!object) {
        self.result = nil;
    }
    [self populateResults];
}

#pragma mark -
#pragma mark NSTableViewDataSource 
#pragma mark -

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [_result.solutions count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    
    NSUInteger columnIndex = [_result.variables indexOfObject:[tableColumn identifier]];
    Solution *solution = [_result.solutions objectAtIndex:row];
    NSString *uri = [solution.values objectAtIndex:columnIndex];
    
    NSString *ns = nil;
    NSString *ln = nil;
    
    NSString *retValue = uri;
    [_uriCache uriForAbbreviatedUri:uri namespace:&ns localName:&ln];
    if (ns && ln) {
        NSString *prefix = [[DefaultNamespaces sharedDefaultNamespaces] prefixForNamespace:ns onlyEnabled:YES];
        if (prefix) {
            retValue = [NSString stringWithFormat:@"%@:%@", prefix, ln];
        }
    }
    
    return retValue;
}

#pragma mark -
#pragma mark TDTableViewDelegate 
#pragma mark -

- (NSString *)tableView:(NSTableView *)aTableView toolTipForCell:(NSCell *)aCell rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)row mouseLocation:(NSPoint)mouseLocation {
    
    NSString *stringValue = [aCell stringValue];
    NSString *uri = [_uriCache uriForAbbreviatedUri:stringValue namespace:NULL localName:NULL];
    return uri;
}

- (NSMenu *)tableView:(NSTableView *)tableView menuForTableColumn:(NSInteger)column row:(NSInteger)row {
    [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
    NSString *stringValue = [[tableView preparedCellAtColumn:column row:row] stringValue];
    NSString *uri = [_uriCache uriForAbbreviatedUri:stringValue namespace:NULL localName:NULL];
    return [tableView nameCopyMenuForUri:uri abbreviatedUri:stringValue];
}

@end
