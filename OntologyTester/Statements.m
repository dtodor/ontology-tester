//
//  Statements.m
//  TestRestKit
//
//  Created by Todor Dimitrov on 8/2/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Statements.h"
#import "RDFTripple.h"

@implementation Statements

@synthesize namespaces=_namespaces;
@synthesize tripples=_tripples;

- (void)dealloc {
    [_namespaces release], _namespaces = nil;
    [_tripples release], _tripples = nil;
    [super dealloc];
}

- (NSString *)description {
    NSString *descr = @"namespaces:\n";
    NSUInteger i = 0;
    for (NSString *namespace in _namespaces) {
        descr = [descr stringByAppendingString:[NSString stringWithFormat:@"\tns%d - %@\n", i++, namespace]];
    }
    descr = [descr stringByAppendingString:@"\ntripples:\n"];
    for (RDFTripple *tripple in _tripples) {
        descr = [descr stringByAppendingString:[NSString stringWithFormat:@"\t%@\n", tripple]];
    }
    return descr;
}

- (NSString *)uriForAbbreviatedUri:(NSString *)uri {
    NSError *error = NULL;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"ns([0-9]+):(.+)"
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:&error];
    NSAssert(regex, @"Unable to create regular expression");
    NSArray *matches = [regex matchesInString:uri options:0 range:NSMakeRange(0, [uri length])];
    if ([matches count] == 1) {
        NSTextCheckingResult *match = [matches objectAtIndex:0];
        NSUInteger index = [[regex replacementStringForResult:match inString:uri offset:0 template:@"$1"] integerValue];
        NSString *localName = [regex replacementStringForResult:match inString:uri offset:0 template:@"$2"];
        if (index < [_namespaces count]) {
            return [NSString stringWithFormat:@"%@%@", [_namespaces objectAtIndex:index], localName];
        }
    }
    return uri;
}

@end
