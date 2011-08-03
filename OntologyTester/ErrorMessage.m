//
//  ErrorMessage.m
//  OntologyTester
//
//  Created by Todor Dimitrov on 8/3/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ErrorMessage.h"

@implementation ErrorMessage

@synthesize message=_message;

- (void)dealloc {
    [_message release], _message = nil;
    [super dealloc];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"A server error occurred, reason:\n\n%@", _message];
}

@end
