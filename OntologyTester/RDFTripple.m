//
//  RDFTripple.m
//  TestRestKit
//
//  Created by Todor Dimitrov on 8/2/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "RDFTripple.h"

@implementation RDFTripple

@synthesize subject=_subject;
@synthesize predicate=_predicate;
@synthesize object=_object;

- (void)dealloc {
    [_subject release], _subject = nil;
    [_predicate release], _predicate = nil;
    [_object release], _object = nil;
    [super dealloc];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"{%@ %@ %@}", _subject, _predicate, _object];
}

@end
