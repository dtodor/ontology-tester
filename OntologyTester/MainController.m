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
#import <RestKit/RestKit.h>

@interface MainController() <RKObjectLoaderDelegate, NSTabViewDelegate>
@end

@implementation MainController

@synthesize statements=_statements;
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
    
    // Register our mappings with the provider
    [objectManager.mappingProvider setMapping:rdfTripple forKeyPath:@"rdfTripple"];
    [objectManager.mappingProvider setMapping:statements forKeyPath:@"statements"];
}

- (void)dealloc {
    [_statements dealloc], _statements = nil;
    [super dealloc];
}

- (IBAction)performQuery:(id)sender {
    [_activityIndicator setHidden:NO];
    [_activityIndicator startAnimation:self];
    
    RKObjectManager *objectManager = [RKObjectManager sharedManager];
    [objectManager loadObjectsAtResourcePath:@"/statements" delegate:self block:^(RKObjectLoader *loader) {
        if ([objectManager.acceptMIMEType isEqualToString:RKMIMETypeJSON]) {
            loader.objectMapping = [objectManager.mappingProvider objectMappingForClass:[Statements class]];
        }
    }];
}

#pragma mark -
#pragma mark RKObjectLoaderDelegate 
#pragma mark -

- (void)objectLoader:(RKObjectLoader *)objectLoader didFailWithError:(NSError *)error {
    [_activityIndicator stopAnimation:self];
    [_activityIndicator setHidden:YES];
    NSLog(@"An error occurred: %@", [error localizedDescription]);
}

- (void)objectLoader:(RKObjectLoader *)objectLoader didLoadObject:(id)object {
    [_activityIndicator stopAnimation:self];
    [_activityIndicator setHidden:YES];
    Statements *stmts = (Statements *)object;
    // NSLog(@"Received object: \n%@", stmts);
    self.statements = stmts;
}

#pragma mark -
#pragma mark NSTabViewDelegate 
#pragma mark -

- (NSString *)tableView:(NSTableView *)aTableView toolTipForCell:(NSCell *)aCell rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)row mouseLocation:(NSPoint)mouseLocation {

    NSString *uri = [_statements uriForAbbreviatedUri:[aCell stringValue]];
    return uri;
}

@end
