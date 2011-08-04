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

#import "Statements.h"
#import "RDFTriple.h"

@implementation Statements {
    NSMutableDictionary *_uriCache;
    NSMutableDictionary *_namespaceCache;
    NSMutableDictionary *_localNameCache;
}

@synthesize namespaces=_namespaces;
@synthesize triples=_triples;

- (id)init {
    self = [super init];
    if (self) {
        _uriCache = [[NSMutableDictionary dictionary] retain];
        _namespaceCache = [[NSMutableDictionary dictionary] retain];
        _localNameCache = [[NSMutableDictionary dictionary] retain];
    }
    return self;
}

- (void)dealloc {
    [_namespaces release], _namespaces = nil;
    [_triples release], _triples = nil;
    [_uriCache release], _uriCache = nil;
    [_namespaceCache release], _namespaceCache = nil;
    [_localNameCache release], _localNameCache = nil;
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
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"ns([0-9]+):(.+)"
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:&error];
    NSAssert(regex, @"Unable to create regular expression");
    NSArray *matches = [regex matchesInString:uri options:0 range:NSMakeRange(0, [uri length])];
    NSString *retValue = uri;
    if ([matches count] == 1) {
        NSTextCheckingResult *match = [matches objectAtIndex:0];
        NSUInteger index = [[regex replacementStringForResult:match inString:uri offset:0 template:@"$1"] integerValue];
        NSString *ln = [regex replacementStringForResult:match inString:uri offset:0 template:@"$2"];
        if (localName) {
            *localName = ln;
            [_localNameCache setObject:ln forKey:uri];
        }
        if (index < [_namespaces count]) {
            NSString *ns = [_namespaces objectAtIndex:index];
            retValue = [NSString stringWithFormat:@"%@%@", ns, ln];
            if (namespace) {
                *namespace = ns;
            }
            [_namespaceCache setObject:ns forKey:uri];
        }
    }
    [_uriCache setObject:retValue forKey:uri];
    return retValue;
}

@end
