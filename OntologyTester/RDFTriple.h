//
//  RDFTriple.h
//  TestRestKit
//
//  Created by Todor Dimitrov on 8/2/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RDFTriple : NSObject

@property (nonatomic, copy) NSString *subject;
@property (nonatomic, copy) NSString *predicate;
@property (nonatomic, copy) NSString *object;

@end
