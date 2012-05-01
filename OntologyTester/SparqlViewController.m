/*
 * Copyright (c) 2012 Todor Dimitrov
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
#import "Ontology.h"
#import "RestKitHelpers.h"
#import "ResultsTableView.h"

@interface SparqlViewController () <RKObjectLoaderDelegate, NSTableViewDataSource, ResultsTableViewDelegate>

@property (nonatomic, strong) SparqlQuery *result;
@property (nonatomic, weak) IBOutlet MainController *mainController;
@property (nonatomic, weak) IBOutlet NSTableView *resultsTable;
@property (nonatomic, assign) IBOutlet NSTextView *queryTextView;
- (IBAction)performQuery:(id)sender;
- (IBAction)populateNamespaces:(id)sender;
- (IBAction)loadPredefinedQuery:(id)sender;

@end


@implementation SparqlViewController {
    URICache *_uriCache;
}

@synthesize mainController = _mainController;
@synthesize queryString = _queryString;
@synthesize font = _font;
@synthesize resultsTable = _resultsTable;
@synthesize queryTextView = _queryTextView;
@synthesize result = _result;
@synthesize predefinedQuery = _predefinedQuery;

- (void)awakeFromNib 
{
    self.font = [NSFont systemFontOfSize:10.0];
    [self populateNamespaces:self];
    [_mainController addObserver:self forKeyPath:@"ontology" options:0 context:NULL];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context 
{
    if ([keyPath isEqualToString:@"ontology"]) {
        NSArray *queries = _mainController.ontology.predefinedQueries;
        if ([queries count] > 0) {
            self.predefinedQuery = [queries objectAtIndex:0];
        } else {
            self.predefinedQuery = nil;
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (IBAction)performQuery:(id)sender 
{
    SparqlQuery *test = [[SparqlQuery alloc] init];
    test.query = self.queryString;
    
    RKObjectManager *objectManager = [RKObjectManager sharedManager];
    _mainController.processing = YES;
    [objectManager postObject:test usingBlock:^(RKObjectLoader *loader) {
        loader.delegate = self;
        loader.serializationMIMEType = RKMIMETypeJSON; // We want to send this request as JSON
        loader.targetObject = nil;  // Map the results back onto a new object instead of self
        // Set up a custom serialization mapping to handle this request
        loader.serializationMapping = [RKObjectMapping serializationMappingUsingBlock:^(RKObjectMapping *mapping) {
            [mapping mapAttributes:@"query", nil];
        }];
        loader.serializationMapping.rootKeyPath = @"sparqlQuery";
    }];
}

- (IBAction)populateNamespaces:(id)sender 
{
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

- (IBAction)loadPredefinedQuery:(id)sender 
{
    self.queryString = [NSString stringWithFormat:@"%@\n", self.predefinedQuery.query];
    NSRange range = { [_queryString length], 0 };
    [_queryTextView setSelectedRange:range];
    [_queryTextView scrollToEndOfDocument:self];
}

- (void)populateResults 
{
    NSArray *columns = [NSArray arrayWithArray:[_resultsTable tableColumns]];
    for (NSTableColumn *column in columns) {
        [_resultsTable removeTableColumn:column];
    }
    if (!_result) {
        return;
    }
    [_resultsTable setColumnAutoresizingStyle:NSTableViewUniformColumnAutoresizingStyle];
    for (NSString *variable in _result.variables) {
        NSTableColumn *varColumn = [[NSTableColumn alloc] initWithIdentifier:variable];
        [[varColumn headerCell] setStringValue:variable];
        [_resultsTable addTableColumn:varColumn];
    }
    [_resultsTable reloadData];
    columns = [_resultsTable tableColumns];
    NSUInteger numberOfRows = [_result.solutions count];
    for (NSTableColumn *column in columns) {
        [column sizeToFit];
        NSUInteger columnIndex = [_resultsTable columnWithIdentifier:[column identifier]];
        CGFloat width = 0;
        for (NSUInteger row = 0; row < numberOfRows; row++) {
            NSCell *cell = [_resultsTable preparedCellAtColumn:columnIndex row:row];
            CGFloat cellWidth = [cell cellSize].width + 1.0;
            if (cellWidth > width) {
                width = cellWidth;
            }
        }
        if (width > [column width]) {
            [column setWidth:width];
        }
    }
}

#pragma mark -
#pragma mark RKObjectLoaderDelegate 
#pragma mark -

- (void)objectLoader:(RKObjectLoader *)objectLoader didFailWithError:(NSError *)error 
{
    _mainController.processing = NO;
    NSLog(@"An error occurred: %@", [error localizedDescription]);
    NSAlert *alert = [NSAlert alertWithError:error];
    [alert beginSheetModalForWindow:[NSApp mainWindow] modalDelegate:nil didEndSelector:nil contextInfo:NULL];
}

- (void)objectLoader:(RKObjectLoader *)objectLoader didLoadObject:(id)object 
{
    _mainController.processing = NO;
    if ([object isKindOfClass:[SparqlQuery class]]) {
        SparqlQuery *result = (SparqlQuery *)object;
        self.result = result;
        _uriCache = [[URICache alloc] initWithNamespaces:result.namespaces];
    } else if (!object) {
        self.result = nil;
    }
    [self populateResults];
}

#pragma mark -
#pragma mark NSTableViewDataSource 
#pragma mark -

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView 
{
    return [_result.solutions count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row 
{
    NSUInteger columnIndex = [_result.variables indexOfObject:[tableColumn identifier]];
    Solution *solution = [_result.solutions objectAtIndex:row];
    NSString *retValue = @"";
    id value = [solution.values objectAtIndex:columnIndex];
    if (!isJerseyNil(value)) {
        NSString *uri = value;
        NSString *ns = nil;
        NSString *ln = nil;
        [_uriCache uriForAbbreviatedUri:uri namespace:&ns localName:&ln];
        if (ns && ln) {
            NSString *prefix = [[DefaultNamespaces sharedDefaultNamespaces] prefixForNamespace:ns onlyEnabled:YES];
            if (prefix) {
                retValue = [NSString stringWithFormat:@"%@:%@", prefix, ln];
            }
        }
    }
    return retValue;
}

#pragma mark -
#pragma mark ResultsTableViewDelegate 
#pragma mark -

- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row 
{
    return NO;
}

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row 
{
    if (![tableView isKindOfClass:[ResultsTableView class]]) {
        return;
    }
    ResultsTableView *resultsTableView = (ResultsTableView *)tableView;
    NSInteger column = [[resultsTableView tableColumns] indexOfObject:tableColumn];
    NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithKeysAndObjects:NSFontAttributeName, [NSFont systemFontOfSize:13.0], nil];
    if (column == resultsTableView.mouseOverColumn && row == resultsTableView.mouseOverRow) {
        NSNumber *underlineStyle = [NSNumber numberWithInt:NSUnderlineStyleSingle|NSUnderlinePatternDot];
        [attributes setObject:underlineStyle forKey:NSUnderlineStyleAttributeName];
        [attributes setObject:[NSColor colorWithCalibratedRed:0.200 green:0.400 blue:0.800 alpha:1.000] forKey:NSForegroundColorAttributeName];
    }
    NSAttributedString *value = [[NSAttributedString alloc] initWithString:[cell stringValue] attributes:attributes];
    [(NSCell *)cell setAttributedStringValue:value];
}

- (NSString *)tableView:(NSTableView *)aTableView toolTipForCell:(NSCell *)aCell rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)row mouseLocation:(NSPoint)mouseLocation 
{
    
    NSString *stringValue = [aCell stringValue];
    NSString *uri = [_uriCache uriForAbbreviatedUri:stringValue namespace:NULL localName:NULL];
    return uri;
}

- (NSMenu *)tableView:(ResultsTableView *)tableView menuForTableColumn:(NSInteger)column row:(NSInteger)row 
{
    NSString *stringValue = [[tableView preparedCellAtColumn:column row:row] stringValue];
    if ([stringValue length] > 0) {
        NSString *uri = [_uriCache uriForAbbreviatedUri:stringValue namespace:NULL localName:NULL];
        return [tableView nameCopyMenuForUri:uri abbreviatedUri:stringValue];
    } else {
        return nil;
    }
}

@end
