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

#import "MainController.h"
#import "Ontology.h"
#import <RestKit/RestKit.h>
#import "PreferencesWindowController.h"
#import "ErrorMessage.h"
#import "NamespacePrefixValueTransformer.h"
#import "SparqlQuery.h"
#import "StatementsViewController.h"
#import "Statements.h"
#import "RDFTriple.h"
#import "SparqlViewController.h"

@interface MainController () <RKObjectLoaderDelegate>

@property (nonatomic, weak) IBOutlet NSProgressIndicator *activityIndicator;
@property (nonatomic, assign) IBOutlet StatementsViewController *statementsViewController;
@property (nonatomic, assign) IBOutlet SparqlViewController *sparqlViewController;
@property (nonatomic, weak) IBOutlet NSTabView *tabBiew;
- (IBAction)refresh:(id)sender;
- (IBAction)openPreferences:(id)sender;

@property (nonatomic, strong) PreferencesWindowController *preferencesController;

@end

@implementation MainController

@synthesize ontology = _ontology;
@synthesize activityIndicator = _activityIndicator;
@synthesize statementsViewController = _statementsViewController;
@synthesize sparqlViewController = _sparqlViewController;
@synthesize tabBiew = _tavBiew;
@synthesize processing = _processing;
@synthesize preferencesController = _preferencesController;

+ (void)initialize 
{
    if (self == [MainController class]) {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"defaults" ofType:@"plist"];
        NSDictionary *defaults = [NSDictionary dictionaryWithContentsOfFile:path];
        [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
        
        {
            NamespacePrefixValueTransformer *transformer = [[NamespacePrefixValueTransformer alloc] init];
            [NSValueTransformer setValueTransformer:transformer forName:@"NamespacePrefixValueTransformer"];
        }
        
        {
            StringLengthValueTransformer *transformer = [[StringLengthValueTransformer alloc] init];
            [NSValueTransformer setValueTransformer:transformer forName:@"StringLengthValueTransformer"];
        }
        
        {
            ArraySizeValueTransformer *transformer = [[ArraySizeValueTransformer alloc] init];
            [NSValueTransformer setValueTransformer:transformer forName:@"ArraySizeValueTransformer"];
        }
    }
}

- (void)awakeFromNib 
{
    [_activityIndicator setHidden:YES];
    
    NSString *address = [[NSUserDefaults standardUserDefaults] stringForKey:@"serverAddress"];
    RKObjectManager *objectManager = [RKObjectManager objectManagerWithBaseURL:[NSURL URLWithString:address]];
    
    // Setup our object mappings
    RKObjectMapping *rdfTriple = [RKObjectMapping mappingForClass:[RDFTriple class]];
    [rdfTriple mapKeyPath:@"s" toAttribute:@"subject"];
    [rdfTriple mapKeyPath:@"p" toAttribute:@"predicate"];
    [rdfTriple mapKeyPath:@"o" toAttribute:@"object"];
    
    RKObjectMapping *statements = [RKObjectMapping mappingForClass:[Statements class]];
    [statements mapAttributes:@"namespaces", nil];
    [statements hasMany:@"triples" withMapping:rdfTriple];
    
    RKObjectMapping *solution = [RKObjectMapping mappingForClass:[Solution class]];
    [solution mapAttributes:@"values", nil];
    
    RKObjectMapping *sparqlQuery = [RKObjectMapping mappingForClass:[SparqlQuery class]];
    [sparqlQuery mapAttributes:@"query", @"name", @"variables", @"namespaces", nil];
    [sparqlQuery hasMany:@"solutions" withMapping:solution];
    
    RKObjectMapping *ontology = [RKObjectMapping mappingForClass:[Ontology class]];
    [ontology mapAttributes:@"namespaces", @"uri", nil];
    [ontology hasMany:@"predefinedQueries" withMapping:sparqlQuery];
    
    RKObjectMapping *errorMessage = [RKObjectMapping mappingForClass:[ErrorMessage class]];
    [errorMessage mapAttributes:@"message", nil];
    
    // Register our mappings with the provider
    [objectManager.mappingProvider setMapping:rdfTriple forKeyPath:@"triple"];
    [objectManager.mappingProvider setMapping:statements forKeyPath:@"statements"];
    [objectManager.mappingProvider setMapping:ontology forKeyPath:@"ontology"];
    [objectManager.mappingProvider setMapping:errorMessage forKeyPath:@"errorMessage"];
    [objectManager.mappingProvider setMapping:solution forKeyPath:@"solution"];
    [objectManager.mappingProvider setMapping:sparqlQuery forKeyPath:@"sparqlQuery"];
    
    [objectManager.router routeClass:[SparqlQuery class] toResourcePath:@"/query" forMethod:RKRequestMethodPOST];
    
    [self addObserver:self forKeyPath:@"ontology" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"processing" options:0 context:NULL];
    [[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:@"serverAddress" options:0 context:NULL];
    
    [[_tavBiew tabViewItemAtIndex:0] setView:_statementsViewController.view];
    [[_tavBiew tabViewItemAtIndex:1] setView:_sparqlViewController.view];
}

- (void)updateNamespacesConfiguration 
{
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
            prefix = [NSString stringWithFormat:@"pfx_%d", i++];
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

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context 
{
    if ([keyPath isEqualToString:@"serverAddress"]) {
        NSString *address = [[NSUserDefaults standardUserDefaults] stringForKey:@"serverAddress"];
        [[RKObjectManager sharedManager].client setBaseURL:[NSURL URLWithString:address]];
    } else if ([keyPath isEqualToString:@"ontology"]) {
        [self updateNamespacesConfiguration];
    } else if ([keyPath isEqualToString:@"processing"]) {
        if (self.processing) {
            [_activityIndicator setHidden:NO];
            [_activityIndicator startAnimation:self];
        } else {
            [_activityIndicator stopAnimation:self];
            [_activityIndicator setHidden:YES];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)dealloc 
{
    [self removeObserver:self forKeyPath:@"ontology"];
    [self removeObserver:self forKeyPath:@"processing"];
    [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:@"serverAddress"];
}

- (IBAction)refresh:(id)sender 
{
    self.processing = YES;
    RKObjectManager *objectManager = [RKObjectManager sharedManager];
    [objectManager loadObjectsAtResourcePath:@"/ontology" delegate:self];
}

- (void)preferencesSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo 
{
    NSLog(@"Close preferences");
    self.preferencesController = nil;
}

- (IBAction)openPreferences:(id)sender 
{
    NSLog(@"Open preferences");
    self.preferencesController = [[PreferencesWindowController alloc] initWithWindowNibName:@"PreferencesWindow"];

    [NSApp beginSheet:self.preferencesController.window 
	   modalForWindow:[NSApp mainWindow] 
		modalDelegate:self 
	   didEndSelector:@selector(preferencesSheetDidEnd:returnCode:contextInfo:) 
		  contextInfo:NULL];
}

#pragma mark -
#pragma mark RKObjectLoaderDelegate 
#pragma mark -

- (void)objectLoader:(RKObjectLoader *)objectLoader didFailWithError:(NSError *)error 
{
    self.processing = NO;
    NSLog(@"An error occurred: %@", [error localizedDescription]);
    NSAlert *alert = [NSAlert alertWithError:error];
    [alert beginSheetModalForWindow:[NSApp mainWindow] modalDelegate:nil didEndSelector:nil contextInfo:NULL];
}

- (void)objectLoader:(RKObjectLoader *)objectLoader didLoadObject:(id)object 
{
    self.processing = NO;
    if ([object isKindOfClass:[Ontology class]]) {
        Ontology *ontology = (Ontology *)object;
        self.ontology = ontology;
    } else if (!object) {
        self.ontology = nil;
    }
}

@end
