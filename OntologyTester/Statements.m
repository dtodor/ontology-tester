//
//  Statements.m
//  TestRestKit
//
//  Created by Todor Dimitrov on 8/2/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Statements.h"
#import "RDFTriple.h"

@implementation Statements {
    NSMutableDictionary *_uriCache;
}

@synthesize namespaces=_namespaces;
@synthesize triples=_triples;

- (id)init {
    self = [super init];
    if (self) {
        _uriCache = [[NSMutableDictionary dictionary] retain];
    }
    return self;
}

- (void)dealloc {
    [_namespaces release], _namespaces = nil;
    [_triples release], _triples = nil;
    [_uriCache release], _uriCache = nil;
    [super dealloc];
}

- (NSString *)description {
    NSString *descr = @"namespaces:\n";
    NSUInteger i = 0;
    for (NSString *namespace in _namespaces) {
        descr = [descr stringByAppendingString:[NSString stringWithFormat:@"\tns%d - %@\n", i++, namespace]];
    }
    descr = [descr stringByAppendingString:@"\ntriples:\n"];
    for (RDFTriple *triple in _triples) {
        descr = [descr stringByAppendingString:[NSString stringWithFormat:@"\t%@\n", triple]];
    }
    return descr;
}

- (NSString *)uriForAbbreviatedUri:(NSString *)uri {
    NSString *cached = [_uriCache objectForKey:uri];
    if (cached) {
        return cached;
    }
    NSError *error = NULL;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"ns([0-9]+):(.+)"
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:&error];
    NSAssert(regex, @"Unable to create regular expression");
    NSArray *matches = [regex matchesInString:uri options:0 range:NSMakeRange(0, [uri length])];
    NSString *retValue = uri;
    if ([matches count] == 1) {
        NSTextCheckingResult *match = [matches objectAtIndex:0];
        NSUInteger index = [[regex replacementStringForResult:match inString:uri offset:0 template:@"$1"] integerValue];
        NSString *localName = [regex replacementStringForResult:match inString:uri offset:0 template:@"$2"];
        if (index < [_namespaces count]) {
            retValue = [NSString stringWithFormat:@"%@%@", [_namespaces objectAtIndex:index], localName];
        }
    }
    [_uriCache setObject:retValue forKey:uri];
    return retValue;
}

@end
