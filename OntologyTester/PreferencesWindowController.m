//
//  PreferencesWindowController.m
//  OntologyTester
//
//  Created by Todor Dimitrov on 8/2/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PreferencesWindowController.h"

@implementation PreferencesWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (IBAction)dismiss:(id)sender {
    [NSApp endSheet:self.window returnCode:0];
	[self.window orderOut:nil];
}

@end
