//
//  RestKitHelpers.m
//  Ontology Tester
//
//  Created by Todor Dimitrov on 8/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "RestKitHelpers.h"

BOOL isJerseyNil(id object) {
    if ([object isKindOfClass:[NSDictionary class]] && [object count] == 1) {
        return [[object objectForKey:@"nil"] boolValue];
    }
    return NO;
}