//
//  Statements.h
//  TestRestKit
//
//  Created by Todor Dimitrov on 8/2/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Statements : NSObject

@property (nonatomic, retain) NSArray *namespaces;
@property (nonatomic, retain) NSArray *tripples;

- (NSString *)uriForAbbreviatedUri:(NSString *)uri;

@end
