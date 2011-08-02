//
//  Ontology.m
//  OntologyTester
//
//  Created by Todor Dimitrov on 8/2/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Ontology.h"

@implementation Ontology

@synthesize namespaces=_namespaces;
@synthesize uri=_uri;

- (void)dealloc {
    [_namespaces release], _namespaces = nil;
    [_uri release], _uri = nil;
    [super dealloc];
}

@end
