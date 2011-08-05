//
//  SparqlViewController.m
//  Ontology Tester
//
//  Created by Todor Dimitrov on 8/5/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "SparqlViewController.h"
#import "DefaultNamespaces.h"
#import <RestKit/RestKit.h>
#import "MainController.h"
#import "SparqlQuery.h"
#import "RDFTriple.h"
#import "DefaultNamespaces.h"
#import "URICache.h"

@interface SparqlViewController() <RKObjectLoaderDelegate, NSTableViewDataSource>

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
    self.font = [NSFont systemFontOfSize:10.0];
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
#pragma mark NSTabViewDelegate 
#pragma mark -

- (NSString *)tableView:(NSTableView *)aTableView toolTipForCell:(NSCell *)aCell rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)row mouseLocation:(NSPoint)mouseLocation {
    
    NSString *stringValue = [aCell stringValue];
    NSString *uri = [_uriCache uriForAbbreviatedUri:stringValue namespace:NULL localName:NULL];
    return uri;
}

@end
