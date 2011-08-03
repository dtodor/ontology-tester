//
//  PreferencesWindowController.h
//  OntologyTester
//
//  Created by Todor Dimitrov on 8/2/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PreferencesWindowController : NSWindowController {
}

@property (assign) IBOutlet NSArrayController *filtersArrayController;
@property (assign) IBOutlet NSTableView *filtersTable;

- (IBAction)dismiss:(id)sender;
- (IBAction)addNewFilter:(id)sender;

@end
