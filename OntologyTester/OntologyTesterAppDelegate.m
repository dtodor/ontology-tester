//
//  OntologyTesterAppDelegate.m
//  OntologyTester
//
//  Created by Todor Dimitrov on 8/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "OntologyTesterAppDelegate.h"

@implementation OntologyTesterAppDelegate

@synthesize window=_window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"NSConstraintBasedLayoutVisualizeMutuallyExclusiveConstraints"];
}

@end
