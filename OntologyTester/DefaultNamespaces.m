/*
 * Copyright (c) 2011 Todor Dimitrov
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 
 * Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 * 
 * Redistributions in binary form must reproduce the above copyright
 * notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution.
 * 
 * Neither the name of the project's author nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 */

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
