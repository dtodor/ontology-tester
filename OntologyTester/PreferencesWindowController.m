//
//  PreferencesWindowController.m
//  OntologyTester
//
//  Created by Todor Dimitrov on 8/2/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PreferencesWindowController.h"

@implementation PreferencesWindowController

@synthesize filtersArrayController=_filtersArrayController;
@synthesize filtersTable=_filtersTable;

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (IBAction)dismiss:(id)sender {
    [NSApp endSheet:self.window returnCode:0];
	[self.window orderOut:nil];
}

- (IBAction)addNewFilter:(id)sender {
    NSMutableDictionary *dictionary = [_filtersArrayController newObject];
    [dictionary setObject:@"Predicate" forKey:@"predicate"];
    [dictionary setObject:[NSNumber numberWithBool:YES] forKey:@"enabled"];
    [_filtersArrayController insertObject:dictionary atArrangedObjectIndex:[[_filtersArrayController arrangedObjects] count]];
    [_filtersTable editColumn:0 row:([[_filtersArrayController arrangedObjects] count]-1) withEvent:nil select:YES];
    [dictionary release];
}

@end
