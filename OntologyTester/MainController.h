//
//  MainController.h
//  OntologyTester
//
//  Created by Todor Dimitrov on 8/2/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Statements;

@interface MainController : NSObject {
}

@property (nonatomic, retain) Statements *statements;
@property (assign) IBOutlet NSProgressIndicator *activityIndicator;

- (IBAction)performQuery:(id)sender;

@end
