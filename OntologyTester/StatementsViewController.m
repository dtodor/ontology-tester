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

#import "StatementsViewController.h"
#import "Ontology.h"
#import "RDFTriple.h"
#import "Statements.h"
#import "NamespacePrefixValueTransformer.h"
#import <RestKit/RestKit.h>
#import "NSAlert-OAExtensions.h"
#import "MainController.h"
#import "URICache.h"
#import "NSTableView+TDExtensions.h"

@interface StatementsViewController() <RKObjectLoaderDelegate, TDTableViewDelegate>
@end

@implementation StatementsViewController

@synthesize statements=_statements;

@synthesize subject=_subject;
@synthesize subjectNS=_subjectNS;
@synthesize predicate=_predicate;
@synthesize predicateNS=_predicateNS;
@synthesize object=_object;
@synthesize objectNS=_objectNS;

@synthesize filterResults=_filterResults;
@synthesize filterPredicate=_filterPredicate;

@synthesize mainController=_mainController;

- (void)awakeFromNib {
    [self addObserver:self forKeyPath:@"filterResults" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"statements" options:0 context:NULL];
    [_mainController addObserver:self forKeyPath:@"ontology" options:0 context:NULL];
}

- (NSPredicate *)buildFilterPredicate {
    NSArray *filters = [[NSUserDefaults standardUserDefaults] arrayForKey:@"filters"];
    NSMutableArray *enabledFilterPredicates = [NSMutableArray array];
    [filters enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSDictionary *filter = (NSDictionary *)obj;
        if ([[filter objectForKey:@"enabled"] boolValue]) {
            [enabledFilterPredicates addObject:[filter objectForKey:@"predicate"]];
        }
    }];
    return [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        RDFTriple *triple = (RDFTriple *)evaluatedObject;
        NSString *triplePredicateUri = [_statements.uriCache uriForAbbreviatedUri:triple.predicate namespace:NULL localName:NULL];
        for (NSString *predicate in enabledFilterPredicates) {
            if ([triplePredicateUri rangeOfString:predicate].location != NSNotFound) {
                return NO;
            }
        }
        return YES;
    }];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"filterResults"]) {
        if (_filterResults) {
            self.filterPredicate = [self buildFilterPredicate];
        } else {
            self.filterPredicate = nil;
        }
    } else if ([keyPath isEqualToString:@"ontology"]) {
        if ([_mainController.ontology.namespaces count] > 0) {
            NSString *defaultNamespace = [_mainController.ontology.namespaces objectAtIndex:0];
            self.subjectNS = defaultNamespace;
            self.predicateNS = defaultNamespace;
            self.objectNS = defaultNamespace;
        } else {
            self.subjectNS = nil;
            self.predicateNS = nil;
            self.objectNS = nil;
        }
    } else if ([keyPath isEqualToString:@"statements"]) {
        NamespacePrefixValueTransformer *transformer = (NamespacePrefixValueTransformer *)[NSValueTransformer valueTransformerForName:@"NamespacePrefixValueTransformer"];
        transformer.statements = self.statements;
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)dealloc {
    [self removeObserver:self forKeyPath:@"filterResults"];
    [self removeObserver:self forKeyPath:@"statements"];
    [_mainController removeObserver:self forKeyPath:@"ontology"];
    
    [_statements dealloc], _statements = nil;
    
    [_subject release], _subject = nil;
    [_subjectNS release], _subjectNS = nil;
    [_predicate release], _predicate = nil;
    [_predicateNS release], _predicateNS = nil;
    [_object release], _object = nil;
    [_objectNS release], _objectNS = nil;
    
    [_filterPredicate release], _filterPredicate = nil;
    
    [super dealloc];
}

- (IBAction)performQuery:(id)sender {
    NSMutableDictionary *queryParams = [NSMutableDictionary dictionary];
    if ([_subject length] > 0) {
        [queryParams setObject:[NSString stringWithFormat:@"%@%@", _subjectNS, _subject] forKey:@"subject"];
    }
    if ([_predicate length] > 0) {
        [queryParams setObject:[NSString stringWithFormat:@"%@%@", _predicateNS, _predicate] forKey:@"predicate"];
    }
    if ([_object length] > 0) {
        [queryParams setObject:[NSString stringWithFormat:@"%@%@", _objectNS, _object] forKey:@"object"];
    }
    NSString *path = @"/statements";
    path = [path appendQueryParams:queryParams];
    
    void (^doQuery)() = ^{
        _mainController.processing = YES;
        RKObjectManager *objectManager = [RKObjectManager sharedManager];
        [objectManager loadObjectsAtResourcePath:path delegate:self];
    };
    
    if ([queryParams count] == 0) {
        OABeginAlertSheet(@"No query", @"No", @"Yes", nil, 
                          [sender window], ^(NSAlert *alert, NSInteger code) {
                              if (code == NSAlertSecondButtonReturn) {
                                  doQuery();
                              }
                          }, @"No query has been specified. Would you like to retrieve all statements from the KB?");
    } else {
        doQuery();
    }
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
    if ([object isKindOfClass:[Statements class]]) {
        self.statements = (Statements *)object;
    } else if (!object) {
        self.statements = nil;
    }
}

#pragma mark -
#pragma mark TDTableViewDelegate 
#pragma mark -

- (NSString *)tableView:(NSTableView *)aTableView toolTipForCell:(NSCell *)aCell rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)row mouseLocation:(NSPoint)mouseLocation {
    
    NSString *stringValue = [aCell stringValue];
    NSString *uri = [_statements.uriCache uriForAbbreviatedUri:stringValue namespace:NULL localName:NULL];
    return uri;
}

- (NSMenu *)tableView:(NSTableView *)tableView menuForTableColumn:(NSInteger)column row:(NSInteger)row {
    [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
    NSString *stringValue = [[tableView preparedCellAtColumn:column row:row] stringValue];
    NSString *uri = [_statements.uriCache uriForAbbreviatedUri:stringValue namespace:NULL localName:NULL];
    return [tableView nameCopyMenuForUri:uri abbreviatedUri:stringValue];
}

@end
