//
//  MainController.h
//  OntologyTester
//
//  Created by Todor Dimitrov on 8/2/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Statements;
@class Ontology;

@interface MainController : NSObject {
}

@property (nonatomic, retain) Statements *statements;
@property (nonatomic, retain) Ontology *ontology;
@property (assign) IBOutlet NSProgressIndicator *activityIndicator;

@property (nonatomic, copy) NSString *subjectNS;
@property (nonatomic, copy) NSString *predicateNS;
@property (nonatomic, copy) NSString *objectNS;

@property (nonatomic, copy) NSString *subject;
@property (nonatomic, copy) NSString *predicate;
@property (nonatomic, copy) NSString *object;

@property (nonatomic) BOOL filterResults;
@property (nonatomic, retain) NSPredicate *filterPredicate;

- (IBAction)performQuery:(id)sender;
- (IBAction)refresh:(id)sender;
- (IBAction)openPreferences:(id)sender;

@end
