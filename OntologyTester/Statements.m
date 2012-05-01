/*
 * Copyright (c) 2012 Todor Dimitrov
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

#import "Statements.h"
#import "RDFTriple.h"
#import "DefaultNamespaces.h"
#import "URICache.h"

@implementation Statements

@synthesize namespaces = _namespaces;
@synthesize triples = _triples;
@synthesize uriCache = _uriCache;

- (id)init 
{
    self = [super init];
    if (self) {
        [self addObserver:self forKeyPath:@"namespaces" options:0 context:NULL];
    }
    return self;
}

- (void)dealloc 
{
    [self removeObserver:self forKeyPath:@"namespaces"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context 
{
    if ([keyPath isEqualToString:@"namespaces"]) {
        _uriCache = [[URICache alloc] initWithNamespaces:_namespaces];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (NSString *)description 
{
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

@end
