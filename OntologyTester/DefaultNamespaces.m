//
//  DefaultNamespaces.m
//  Ontology Tester
//
//  Created by Todor Dimitrov on 8/5/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "DefaultNamespaces.h"

@implementation DefaultNamespaces {
    NSMutableDictionary *_prefix2namespace;
    NSMutableDictionary *_namespace2prefix;
    NSMutableDictionary *_enabledNamespaces;
}

+ (DefaultNamespaces *)sharedDefaultNamespaces {
    static dispatch_once_t onceToken;
    static DefaultNamespaces *instance = nil;
    dispatch_once(&onceToken, ^{
        instance = [[DefaultNamespaces alloc] init];
    });
    return instance;
}

- (void)initNamespaces {
    [_prefix2namespace removeAllObjects];
    [_namespace2prefix removeAllObjects];
    [_enabledNamespaces removeAllObjects];
    NSArray *namespaces = [[NSUserDefaults standardUserDefaults] arrayForKey:@"namespaces"];
    for (NSDictionary *namespaceConfig in namespaces) {
        NSString *namespace = [namespaceConfig objectForKey:@"namespace"];
        NSString *prefix = [namespaceConfig objectForKey:@"prefix"];
        BOOL enabled = [[namespaceConfig objectForKey:@"enabled"] boolValue];
        [_prefix2namespace setObject:namespace forKey:prefix];
        [_namespace2prefix setObject:prefix forKey:namespace];
        [_enabledNamespaces setObject:[NSNumber numberWithBool:enabled] forKey:namespace];
    }
}

- (id)init {
    self = [super init];
    if (self) {
        _prefix2namespace = [[NSMutableDictionary alloc] init];
        _namespace2prefix = [[NSMutableDictionary alloc] init];
        _enabledNamespaces = [[NSMutableDictionary alloc] init];
        [self initNamespaces];
        [[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:@"namespaces" options:0 context:NULL];
    }
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"namespaces"]) {
        [self initNamespaces];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)dealloc {
    [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:@"namespaces"];
    [_prefix2namespace release], _prefix2namespace = nil;
    [_namespace2prefix release], _namespace2prefix = nil;
    [_enabledNamespaces release], _enabledNamespaces = nil;
	[super dealloc];
}

- (NSString *)prefixForNamespace:(NSString *)namespace onlyEnabled:(BOOL)enabled {
    if (enabled && ![[_enabledNamespaces objectForKey:namespace] boolValue]) {
        return nil;
    }
    return [_namespace2prefix objectForKey:namespace];
}

- (NSString *)namespaceForPerfix:(NSString *)prefix {
    return [_prefix2namespace objectForKey:prefix];
}

- (NSSet *)namespaces {
    return [_namespace2prefix keysOfEntriesPassingTest:^BOOL(id key, id obj, BOOL *stop) {
        return YES;
    }];
}

@end
