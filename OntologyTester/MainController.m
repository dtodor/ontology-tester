//
//  MainController.m
//  OntologyTester
//
//  Created by Todor Dimitrov on 8/2/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MainController.h"
#import "RDFTripple.h"
#import "Statements.h"
#import "Ontology.h"
#import <RestKit/RestKit.h>
#import "PreferencesWindowController.h"

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

- (void)awakeFromNib {
    [_activityIndicator setHidden:YES];
    
    RKObjectManager *objectManager = [RKObjectManager objectManagerWithBaseURL:@"http://localhost:8081"];
    
    // Setup our object mappings
    RKObjectMapping *rdfTripple = [RKObjectMapping mappingForClass:[RDFTripple class]];
    [rdfTripple mapKeyPath:@"s" toAttribute:@"subject"];
    [rdfTripple mapKeyPath:@"p" toAttribute:@"predicate"];
    [rdfTripple mapKeyPath:@"o" toAttribute:@"object"];
    
    RKObjectMapping *statements = [RKObjectMapping mappingForClass:[Statements class]];
    [statements mapAttributes:@"namespaces", nil];
    [statements hasMany:@"tripples" withMapping:rdfTripple];
    
    RKObjectMapping *ontology = [RKObjectMapping mappingForClass:[Ontology class]];
    [ontology mapAttributes:@"namespaces", @"uri", nil];
    
    // Register our mappings with the provider
    [objectManager.mappingProvider setMapping:rdfTripple forKeyPath:@"tripple"];
    [objectManager.mappingProvider setMapping:statements forKeyPath:@"statements"];
    [objectManager.mappingProvider setMapping:ontology forKeyPath:@"ontology"];
    
    [self addObserver:self forKeyPath:@"filterResults" options:0 context:NULL];
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
        RDFTripple *tripple = (RDFTripple *)evaluatedObject;
        NSString *tripplePredicateUri = [_statements uriForAbbreviatedUri:tripple.predicate];
        for (NSString *predicate in enabledFilterPredicates) {
            if ([tripplePredicateUri rangeOfString:predicate].location != NSNotFound) {
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
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)dealloc {
    [self removeObserver:self forKeyPath:@"filterResults"];
    
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
    [_activityIndicator setHidden:NO];
    [_activityIndicator startAnimation:self];
    
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
    
    _requestType = RequestType_Statements;
    RKObjectManager *objectManager = [RKObjectManager sharedManager];
    [objectManager loadObjectsAtResourcePath:path delegate:self];
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
    [alert runModal];
}

- (void)objectLoader:(RKObjectLoader *)objectLoader didLoadObject:(id)object {
    [_activityIndicator stopAnimation:self];
    [_activityIndicator setHidden:YES];
    if ([object isKindOfClass:[Ontology class]]) {
        Ontology *ontology = (Ontology *)object;
        // NSLog(@"Received object: \n%@", ontology);
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
        // NSLog(@"Received object: \n%@", stmts);
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

    NSString *uri = [_statements uriForAbbreviatedUri:[aCell stringValue]];
    return uri;
}

@end
