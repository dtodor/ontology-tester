//
//  URICache.h
//  Ontology Tester
//
//  Created by Todor Dimitrov on 8/5/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface URICache : NSObject

- (id)initWithNamespaces:(NSArray *)namespaces;
- (NSString *)uriForAbbreviatedUri:(NSString *)uri namespace:(NSString **)namespace localName:(NSString **)localName;

@end
