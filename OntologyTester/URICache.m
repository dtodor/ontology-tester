//
//  URICache.m
//  Ontology Tester
//
//  Created by Todor Dimitrov on 8/5/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "URICache.h"
#import "DefaultNamespaces.h"

@implementation URICache {
    NSMutableDictionary *_uriCache;
    NSMutableDictionary *_namespaceCache;
    NSMutableDictionary *_localNameCache;
    
    NSArray *_namespaces;
}

- (id)initWithNamespaces:(NSArray *)namespaces {
    self = [super init];
    if (self) {
        _uriCache = [[NSMutableDictionary dictionary] retain];
        _namespaceCache = [[NSMutableDictionary dictionary] retain];
        _localNameCache = [[NSMutableDictionary dictionary] retain];
        
        _namespaces = [namespaces retain];
    }
    return self;
}

- (void)dealloc {
    [_uriCache release], _uriCache = nil;
    [_namespaceCache release], _namespaceCache = nil;
    [_localNameCache release], _localNameCache = nil;
    
    [_namespaces release], _namespaces = nil;
    [super dealloc];
}

- (NSString *)uriForAbbreviatedUri:(NSString *)uri namespace:(NSString **)namespace localName:(NSString **)localName {
    NSString *cached = [_uriCache objectForKey:uri];
    if (cached) {
        if (namespace) {
            *namespace = [_namespaceCache objectForKey:uri];
        }
        if (localName) {
            *localName = [_localNameCache objectForKey:uri];
        }
        return cached;
    }
    
    NSError *error = NULL;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"(ns([0-9]+)|.+):(.+)"
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:&error];
    NSArray *matches = [regex matchesInString:uri options:0 range:NSMakeRange(0, [uri length])];
    NSString *retValue = uri;
    if ([matches count] == 1) {
        NSTextCheckingResult *match = [matches objectAtIndex:0];
        NSString *prefix = [regex replacementStringForResult:match inString:uri offset:0 template:@"$1"];
        NSString *ln = [regex replacementStringForResult:match inString:uri offset:0 template:@"$3"];
        [_localNameCache setObject:ln forKey:uri];
        if (localName) {
            *localName = ln;
        }
        NSString *ns = nil;
        if ([match rangeAtIndex:2].location != NSNotFound) {
            NSUInteger index = [[regex replacementStringForResult:match inString:uri offset:0 template:@"$2"] integerValue];
            if (index < [_namespaces count]) {
                ns = [_namespaces objectAtIndex:index];
            }
        } else {
            ns = [[DefaultNamespaces sharedDefaultNamespaces] namespaceForPerfix:prefix];
        }
        if (namespace) {
            *namespace = ns;
        }
        if (ns) {
            [_namespaceCache setObject:ns forKey:uri];
            retValue = [NSString stringWithFormat:@"%@%@", ns, ln];
        }
    }
    [_uriCache setObject:retValue forKey:uri];
    return retValue;
}

@end
