//
//  StatementsViewController.h
//  Ontology Tester
//
//  Created by Todor Dimitrov on 8/5/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Statements;
@class MainController;

@interface StatementsViewController : NSViewController

@property (nonatomic, retain) Statements *statements;

@property (nonatomic, copy) NSString *subjectNS;
@property (nonatomic, copy) NSString *predicateNS;
@property (nonatomic, copy) NSString *objectNS;

@property (nonatomic, copy) NSString *subject;
@property (nonatomic, copy) NSString *predicate;
@property (nonatomic, copy) NSString *object;

@property (nonatomic) BOOL filterResults;
@property (nonatomic, retain) NSPredicate *filterPredicate;

@property (assign) IBOutlet MainController *mainController;

- (IBAction)performQuery:(id)sender;

@end
