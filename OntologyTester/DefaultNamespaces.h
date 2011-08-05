//
//  DefaultNamespaces.h
//  Ontology Tester
//
//  Created by Todor Dimitrov on 8/5/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DefaultNamespaces : NSObject

- (NSString *)prefixForNamespace:(NSString *)namespace onlyEnabled:(BOOL)enabled;
- (NSString *)namespaceForPerfix:(NSString *)prefix;
- (NSSet *)namespaces;

+ (DefaultNamespaces *)sharedDefaultNamespaces;

@end
