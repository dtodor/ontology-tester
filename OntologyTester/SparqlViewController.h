//
//  SparqlViewController.h
//  Ontology Tester
//
//  Created by Todor Dimitrov on 8/5/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MainController;

@interface SparqlViewController : NSViewController {
}

@property (assign) IBOutlet MainController *mainController;
@property (nonatomic, copy) NSString *queryString;
@property (nonatomic, retain) NSFont *font;
@property (assign) IBOutlet NSTableView *resultsTable;

- (IBAction)performQuery:(id)sender;

@end
