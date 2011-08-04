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

#import "MainController.h"
#import "RDFTriple.h"
#import "Statements.h"
#import "Ontology.h"
#import <RestKit/RestKit.h>
#import "PreferencesWindowController.h"
#import "NSAlert-OAExtensions.h"
#import "ErrorMessage.h"
#import "NamespacePrefixValueTransformer.h"

@interface MainController() <RKObjectLoaderDelegate, NSTabViewDelegate>
@end

typedef enum {
    RequestType_Ontology,
    RequestType_Statements
} RequestType;

@implementation MainController {
    RequestType _requestType;
}

@synthesize statements=_statements;
@synthesize ontology=_ontology;

@synthesize subject=_subject;
@synthesize subjectNS=_subjectNS;
@synthesize predicate=_predicate;
@synthesize predicateNS=_predicateNS;
@synthesize object=_object;
@synthesize objectNS=_objectNS;

@synthesize filterResults=_filterResults;
@synthesize filterPredicate=_filterPredicate;

@synthesize activityIndicator=_activityIndicator;

+ (void)initialize {
    if (self == [MainController class]) {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"defaults" ofType:@"plist"];
        NSDictionary *defaults = [NSDictionary dictionaryWithContentsOfFile:path];
        [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
        
        NamespacePrefixValueTransformer *transformer = [[NamespacePrefixValueTransformer alloc] init];
        [NSValueTransformer setValueTransformer:transformer forName:@"NamespacePrefixValueTransformer"];
    }
}

- (void)awakeFromNib {
    [_activityIndicator setHidden:YES];
    
    NSString *address = [[NSUserDefaults standardUserDefaults] stringForKey:@"serverAddress"];
    RKObjectManager *objectManager = [RKObjectManager objectManagerWithBaseURL:address];
    
    // Setup our object mappings
    RKObjectMapping *rdfTriple = [RKObjectMapping mappingForClass:[RDFTriple class]];
    [rdfTriple mapKeyPath:@"s" toAttribute:@"subject"];
    [rdfTriple mapKeyPath:@"p" toAttribute:@"predicate"];
    [rdfTriple mapKeyPath:@"o" toAttribute:@"object"];
    
    RKObjectMapping *statements = [RKObjectMapping mappingForClass:[Statements class]];
    [statements mapAttributes:@"namespaces", nil];
    [statements hasMany:@"triples" withMapping:rdfTriple];
    
    RKObjectMapping *ontology = [RKObjectMapping mappingForClass:[Ontology class]];
    [ontology mapAttributes:@"namespaces", @"uri", nil];
    
    RKObjectMapping *errorMessage = [RKObjectMapping mappingForClass:[ErrorMessage class]];
    [errorMessage mapAttributes:@"message", nil];
    
    // Register our mappings with the provider
    [objectManager.mappingProvider setMapping:rdfTriple forKeyPath:@"triple"];
    [objectManager.mappingProvider setMapping:statements forKeyPath:@"statements"];
    [objectManager.mappingProvider setMapping:ontology forKeyPath:@"ontology"];
    [objectManager.mappingProvider setMapping:errorMessage forKeyPath:@"errorMessage"];
    
    [self addObserver:self forKeyPath:@"filterResults" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"statements" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"ontology" options:0 context:NULL];
    [[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:@"serverAddress" options:0 context:NULL];
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
        NSString *triplePredicateUri = [_statements uriForAbbreviatedUri:triple.predicate namespace:NULL localName:NULL];
        for (NSString *predicate in enabledFilterPredicates) {
            if ([triplePredicateUri rangeOfString:predicate].location != NSNotFound) {
                return NO;
            }
        }
        return YES;
    }];
}

- (void)updateNamespacesConfiguration {
    if (!self.ontology.namespaces) {
        return;
    }
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray *namespaceConfigs = [defaults mutableArrayValueForKey:@"namespaces"];
    NSArray *oldNamespaces = [namespaceConfigs valueForKeyPath:@"namespace"];
    NSArray *oldNamespacePrefixes = [namespaceConfigs valueForKeyPath:@"prefix"];
    NSMutableArray *newNamespaces = [NSMutableArray arrayWithArray:self.ontology.namespaces];
    if (oldNamespaces) {
        [newNamespaces removeObjectsInArray:oldNamespaces];
    }
    NSMutableArray *namespacePrefixes = [NSMutableArray array];
    if (oldNamespacePrefixes) {
        [namespacePrefixes addObjectsFromArray:oldNamespacePrefixes];
    }
    NSUInteger i = 0;
    for (NSString *namespace in newNamespaces) {
        NSString *prefix = nil;
        while (true) {
            prefix = [NSString stringWithFormat:@"_ns%d_", i++];
            if (![namespacePrefixes containsObject:prefix]) {
                [namespacePrefixes addObject:prefix];
                break;
            }
        }
        NSMutableDictionary *config = [NSMutableDictionary dictionary];
        [config setObject:namespace forKey:@"namespace"];
        [config setObject:prefix forKey:@"prefix"];
        [config setObject:[NSNumber numberWithBool:NO] forKey:@"enabled"];
        [namespaceConfigs addObject:config];
    }
    if ([newNamespaces count] > 0) {
        [defaults setObject:namespaceConfigs forKey:@"namespaces"];
        [defaults synchronize];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"filterResults"]) {
        if (_filterResults) {
            self.filterPredicate = [self buildFilterPredicate];
        } else {
            self.filterPredicate = nil;
        }
    } else if ([keyPath isEqualToString:@"serverAddress"]) {
        NSString *address = [[NSUserDefaults standardUserDefaults] stringForKey:@"serverAddress"];
        [[RKObjectManager sharedManager].client setBaseURL:address];
    } else if ([keyPath isEqualToString:@"statements"]) {
        NamespacePrefixValueTransformer *transformer = (NamespacePrefixValueTransformer *)[NSValueTransformer valueTransformerForName:@"NamespacePrefixValueTransformer"];
        transformer.statements = self.statements;
    } else if ([keyPath isEqualToString:@"ontology"]) {
        [self updateNamespacesConfiguration];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)dealloc {
    [self removeObserver:self forKeyPath:@"filterResults"];
    [self removeObserver:self forKeyPath:@"statements"];
    [self removeObserver:self forKeyPath:@"ontology"];
    [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:@"serverAddress"];
    
    [_statements dealloc], _statements = nil;
    [_ontology dealloc], _ontology = nil;
    
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
        [_activityIndicator setHidden:NO];
        [_activityIndicator startAnimation:self];
        
        _requestType = RequestType_Statements;
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

- (IBAction)refresh:(id)sender {
    [_activityIndicator setHidden:NO];
    [_activityIndicator startAnimation:self];

    _requestType = RequestType_Ontology;
    RKObjectManager *objectManager = [RKObjectManager sharedManager];
    [objectManager loadObjectsAtResourcePath:@"/ontology" delegate:self];
}

- (void)preferencesSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    NSLog(@"Close preferences");
    [(PreferencesWindowController *)contextInfo release];
}

- (IBAction)openPreferences:(id)sender {
    NSLog(@"Open preferences");
    PreferencesWindowController *preferencesWindowController = [[PreferencesWindowController alloc] initWithWindowNibName:@"PreferencesWindow"];

    [NSApp beginSheet:preferencesWindowController.window 
	   modalForWindow:[NSApp mainWindow] 
		modalDelegate:self 
	   didEndSelector:@selector(preferencesSheetDidEnd:returnCode:contextInfo:) 
		  contextInfo:preferencesWindowController];
}

#pragma mark -
#pragma mark RKObjectLoaderDelegate 
#pragma mark -

- (void)objectLoader:(RKObjectLoader *)objectLoader didFailWithError:(NSError *)error {
    [_activityIndicator stopAnimation:self];
    [_activityIndicator setHidden:YES];
    NSLog(@"An error occurred: %@", [error localizedDescription]);
    NSAlert *alert = [NSAlert alertWithError:error];
    [alert beginSheetModalForWindow:[NSApp mainWindow] modalDelegate:nil didEndSelector:nil contextInfo:NULL];
}

- (void)objectLoader:(RKObjectLoader *)objectLoader didLoadObject:(id)object {
    [_activityIndicator stopAnimation:self];
    [_activityIndicator setHidden:YES];
    if ([object isKindOfClass:[Ontology class]]) {
        Ontology *ontology = (Ontology *)object;
        self.ontology = ontology;
        if ([ontology.namespaces count] > 0) {
            NSString *defaultNamespace = [ontology.namespaces objectAtIndex:0];
            self.subjectNS = defaultNamespace;
            self.predicateNS = defaultNamespace;
            self.objectNS = defaultNamespace;
        } else {
            self.subjectNS = nil;
            self.predicateNS = nil;
            self.objectNS = nil;
        }
    } else if ([object isKindOfClass:[Statements class]]) {
        Statements *stmts = (Statements *)object;
        self.statements = stmts;
    } else if (!object) {
        switch (_requestType) {
            case RequestType_Ontology:
                self.ontology = nil;
                self.statements = nil;
                break;
            case RequestType_Statements:
                self.statements = nil;
                break;
            default:
                break;
        }
    }
}

#pragma mark -
#pragma mark NSTabViewDelegate 
#pragma mark -

- (NSString *)tableView:(NSTableView *)aTableView toolTipForCell:(NSCell *)aCell rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)row mouseLocation:(NSPoint)mouseLocation {

    NSString *uri = [_statements uriForAbbreviatedUri:[aCell stringValue] namespace:NULL localName:NULL];
    return uri;
}

@end
