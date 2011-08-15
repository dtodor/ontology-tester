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
#import "History.h"
#import "ResultsTableView.h"

@interface StatementsViewController() <RKObjectLoaderDelegate, ResultsTableViewDelegate>
@end

@implementation StatementsViewController

@synthesize statements=_statements;

@synthesize subject=_subject;
@synthesize subjectNS=_subjectNS;
@synthesize predicate=_predicate;
@synthesize predicateNS=_predicateNS;
@synthesize object=_object;
@synthesize objectNS=_objectNS;

@synthesize history=_history;

@synthesize filterResults=_filterResults;
@synthesize filterPredicate=_filterPredicate;

@synthesize mainController=_mainController;
@synthesize historyControl=_historyControl;

- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        _history = [[History alloc] init];
    }
    return self;
}

- (void)awakeFromNib {
    [self addObserver:self forKeyPath:@"filterResults" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"statements" options:0 context:NULL];

    [_history addObserver:self forKeyPath:@"canGoBack" options:0 context:NULL];
    [_history addObserver:self forKeyPath:@"canGoForward" options:0 context:NULL];
    
    [_mainController addObserver:self forKeyPath:@"ontology" options:0 context:NULL];
}

- (NSPredicate *)buildFilterPredicate {
    NSArray *filters = [[NSUserDefaults standardUserDefaults] arrayForKey:@"filters"];
    NSMutableArray *enabledFilters = [NSMutableArray array];
    [filters enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSDictionary *filter = (NSDictionary *)obj;
        if ([[filter objectForKey:@"enabled"] boolValue]) {
            [enabledFilters addObject:filter];
        }
    }];
    return [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        RDFTriple *triple = (RDFTriple *)evaluatedObject;
        NSString *tripleSubjectUri = nil;
        NSString *triplePredicateUri = nil;
        NSString *tripleObjectUri = nil;
        for (NSDictionary *filter in enabledFilters) {
            NSString *filteredUri = [filter objectForKey:@"uri"];
            if ([[filter objectForKey:@"subject"] boolValue]) {
                if (!tripleSubjectUri) {
                    tripleSubjectUri = [_statements.uriCache uriForAbbreviatedUri:triple.subject namespace:NULL localName:NULL];
                }
                if ([tripleSubjectUri rangeOfString:filteredUri].location != NSNotFound) {
                    return NO;
                }
            }
            if ([[filter objectForKey:@"predicate"] boolValue]) {
                if (!triplePredicateUri) {
                    triplePredicateUri = [_statements.uriCache uriForAbbreviatedUri:triple.predicate namespace:NULL localName:NULL];
                }
                if ([triplePredicateUri rangeOfString:filteredUri].location != NSNotFound) {
                    return NO;
                }
            }
            if ([[filter objectForKey:@"object"] boolValue]) {
                if (!tripleObjectUri) {
                    tripleObjectUri = [_statements.uriCache uriForAbbreviatedUri:triple.object namespace:NULL localName:NULL];
                }
                if ([tripleObjectUri rangeOfString:filteredUri].location != NSNotFound) {
                    return NO;
                }
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
    } else if ([keyPath isEqualToString:@"canGoBack"]) {
        [_historyControl setEnabled:_history.canGoBack forSegment:0];
    } else if ([keyPath isEqualToString:@"canGoForward"]) {
        [_historyControl setEnabled:_history.canGoForward forSegment:1];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)dealloc {
    [_history removeObserver:self forKeyPath:@"canGoBack"];
    [_history removeObserver:self forKeyPath:@"canGoForward"];

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
    
    [_history release], _history = nil;
    
    [_filterPredicate release], _filterPredicate = nil;
    
    [super dealloc];
}

- (IBAction)performQuery:(id)sender {
    NSMutableDictionary *queryParams = [NSMutableDictionary dictionary];
    if ([_subject length] > 0) {
        if ([_subjectNS length] > 0) {
            [queryParams setObject:[NSString stringWithFormat:@"%@%@", _subjectNS, _subject] forKey:@"subject"];
        } else {
            [queryParams setObject:[NSString stringWithFormat:@"%@", _subject] forKey:@"subject"];
        }
    }
    if ([_predicate length] > 0) {
        if ([_predicateNS length] > 0) {
            [queryParams setObject:[NSString stringWithFormat:@"%@%@", _predicateNS, _predicate] forKey:@"predicate"];
        } else {
            [queryParams setObject:[NSString stringWithFormat:@"%@", _predicate] forKey:@"predicate"];
        }
    }
    if ([_object length] > 0) {
        if ([_objectNS length] > 0) {
            [queryParams setObject:[NSString stringWithFormat:@"%@%@", _objectNS, _object] forKey:@"object"];
        } else {
            [queryParams setObject:[NSString stringWithFormat:@"%@", _object] forKey:@"object"];
        }
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
        [_history addToHistoryWithSubject:_subject 
                                subjectNS:_subjectNS 
                                predicate:_predicate 
                              predicateNS:_predicateNS 
                                   object:_object 
                                 objectNS:_objectNS];
        doQuery();
    }
}

- (IBAction)goToHistory:(id)sender {
    HistoryItem *historyItem = nil;
    if ([_historyControl selectedSegment] == 0) {
        historyItem = [_history goBack];
    } else {
        historyItem = [_history goForward];
    }
    if (historyItem) {
        self.subject = historyItem.subject;
        self.subjectNS = historyItem.subjectNS;
        self.predicate = historyItem.predicate;
        self.predicateNS = historyItem.predicateNS;
        self.object = historyItem.object;
        self.objectNS = historyItem.objectNS;
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
#pragma mark ResultsTableViewDelegate 
#pragma mark -

- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row {
    return NO;
}

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if (![tableView isKindOfClass:[ResultsTableView class]]) {
        return;
    }
    ResultsTableView *resultsTableView = (ResultsTableView *)tableView;
    NSInteger column = [[resultsTableView tableColumns] indexOfObject:tableColumn];
    NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithKeysAndObjects:NSFontAttributeName, [NSFont systemFontOfSize:13.0], nil];
    if (column == resultsTableView.mouseOverColumn && row == resultsTableView.mouseOverRow) {
        NSNumber *underlineStyle = [NSNumber numberWithInt:NSUnderlineStyleSingle|NSUnderlinePatternDot];
        [attributes setObject:underlineStyle forKey:NSUnderlineStyleAttributeName];
        [attributes setObject:[NSColor colorWithCalibratedRed:1.000 green:0.200 blue:0.200 alpha:1.000] forKey:NSForegroundColorAttributeName];
    }
    NSAttributedString *value = [[NSAttributedString alloc] initWithString:[cell stringValue] attributes:attributes];
    [(NSCell *)cell setAttributedStringValue:value];
    [value release];
}

- (NSString *)tableView:(NSTableView *)aTableView toolTipForCell:(NSCell *)aCell rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)row mouseLocation:(NSPoint)mouseLocation {
    
    NSString *stringValue = [aCell stringValue];
    NSString *uri = [_statements.uriCache uriForAbbreviatedUri:stringValue namespace:NULL localName:NULL];
    return uri;
}

typedef enum {
    SelectAction_Subject = 0x01,
    SelectAction_Predicate = 0x02,
    SelectAction_Object = 0x03,
    SelectAction_ClearRest = 0x04
} SelectAction;

- (void)selectSubjectPredicateObject:(NSMenuItem *)item {
    NSDictionary *representedObject = [item representedObject];
    NSString *ns = [representedObject objectForKey:@"namespace"];
    NSString *ln = [representedObject objectForKey:@"localName"];
    NSInteger tag = [item tag];
    if ((tag & SelectAction_ClearRest) == SelectAction_ClearRest) {
        self.subject = nil;
        self.predicate = nil;
        self.object = nil;
    }
    SelectAction action = (SelectAction)([item tag] & SelectAction_Object);
    switch (action) {
        case SelectAction_Subject:
            self.subjectNS = ns;
            self.subject = ln;
            break;
        case SelectAction_Predicate:
            self.predicateNS = ns;
            self.predicate = ln;
            break;
        case SelectAction_Object:
            self.objectNS = ns;
            self.object = ln;
            break;
        default:
            break;
    }
}

- (NSMenu *)tableView:(ResultsTableView *)tableView menuForTableColumn:(NSInteger)column row:(NSInteger)row {

    NSString *stringValue = [[tableView preparedCellAtColumn:column row:row] stringValue];
    NSString *ns = nil;
    NSString *ln = nil;
    NSString *uri = [_statements.uriCache uriForAbbreviatedUri:stringValue namespace:&ns localName:&ln];
    NSMenu *menu = [tableView nameCopyMenuForUri:uri abbreviatedUri:stringValue];
    
    [menu addItem:[NSMenuItem separatorItem]];
    NSMutableDictionary *representedObject = [NSMutableDictionary dictionary];
    if (ns) {
        [representedObject setObject:ns forKey:@"namespace"];
        [representedObject setObject:ln forKey:@"localName"];
    } else {
        [representedObject setObject:uri forKey:@"localName"];
    }
    {
        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:@"Select As Subject" action:@selector(selectSubjectPredicateObject:) keyEquivalent:@""];
        [item setTag:SelectAction_Subject];
        [item setRepresentedObject:representedObject];
        [item setTarget:self];
        [menu addItem:item];
        [item release];

        NSMenuItem *itemAlt = [[NSMenuItem alloc] initWithTitle:@"Select As Subject And Clear Rest" action:@selector(selectSubjectPredicateObject:) keyEquivalent:@""];
        [itemAlt setTag:SelectAction_Subject|SelectAction_ClearRest];
        [itemAlt setAlternate:YES];
        [itemAlt setKeyEquivalentModifierMask:NSAlternateKeyMask];
        [itemAlt setRepresentedObject:representedObject];
        [itemAlt setTarget:self];
        [menu addItem:itemAlt];
        [itemAlt release];
    }
    {
        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:@"Select As Predicate" action:@selector(selectSubjectPredicateObject:) keyEquivalent:@""];
        [item setTag:SelectAction_Predicate];
        [item setRepresentedObject:representedObject];
        [item setTarget:self];
        [menu addItem:item];
        [item release];
        
        NSMenuItem *itemAlt = [[NSMenuItem alloc] initWithTitle:@"Select As Predicate And Clear Rest" action:@selector(selectSubjectPredicateObject:) keyEquivalent:@""];
        [itemAlt setTag:SelectAction_Predicate|SelectAction_ClearRest];
        [itemAlt setAlternate:YES];
        [itemAlt setKeyEquivalentModifierMask:NSAlternateKeyMask];
        [itemAlt setRepresentedObject:representedObject];
        [itemAlt setTarget:self];
        [menu addItem:itemAlt];
        [itemAlt release];
    }
    {
        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:@"Select As Object" action:@selector(selectSubjectPredicateObject:) keyEquivalent:@""];
        [item setTag:SelectAction_Object];
        [item setRepresentedObject:representedObject];
        [item setTarget:self];
        [menu addItem:item];
        [item release];
        
        NSMenuItem *itemAlt = [[NSMenuItem alloc] initWithTitle:@"Select As Object And Clear Rest" action:@selector(selectSubjectPredicateObject:) keyEquivalent:@""];
        [itemAlt setTag:SelectAction_Object|SelectAction_ClearRest];
        [itemAlt setAlternate:YES];
        [itemAlt setKeyEquivalentModifierMask:NSAlternateKeyMask];
        [itemAlt setRepresentedObject:representedObject];
        [itemAlt setTarget:self];
        [menu addItem:itemAlt];
        [itemAlt release];
    }
    
    return menu;
}

@end
