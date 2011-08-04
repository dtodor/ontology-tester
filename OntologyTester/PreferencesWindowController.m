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

#import "PreferencesWindowController.h"

@implementation PreferencesWindowController

@synthesize filtersArrayController=_filtersArrayController;
@synthesize filtersTable=_filtersTable;
@synthesize namespacesArrayController=_namespacesArrayController;
@synthesize namespacesTable=_namespacesTable;

- (IBAction)dismiss:(id)sender {
    [NSApp endSheet:self.window returnCode:0];
	[self.window orderOut:nil];
}

- (IBAction)addNewFilter:(id)sender {
    NSMutableDictionary *dictionary = [_filtersArrayController newObject];
    [dictionary setObject:@"Predicate" forKey:@"predicate"];
    [dictionary setObject:[NSNumber numberWithBool:YES] forKey:@"enabled"];
    [_filtersArrayController insertObject:dictionary atArrangedObjectIndex:[[_filtersArrayController arrangedObjects] count]];
    
    NSUInteger newRow = [[_filtersArrayController arrangedObjects] count]-1;
    [_filtersTable selectRowIndexes:[NSIndexSet indexSetWithIndex:newRow] byExtendingSelection:NO];
    [_filtersTable editColumn:0 row:newRow withEvent:nil select:YES];
    [dictionary release];
}

- (IBAction)addNewNamespace:(id)sender {
    NSMutableDictionary *dictionary = [_namespacesArrayController newObject];
    [dictionary setObject:@"Namespace" forKey:@"namespace"];
    [dictionary setObject:@"Prefix" forKey:@"prefix"];
    [dictionary setObject:[NSNumber numberWithBool:YES] forKey:@"enabled"];
    [_namespacesArrayController insertObject:dictionary atArrangedObjectIndex:[[_namespacesArrayController arrangedObjects] count]];

    NSUInteger newRow = [[_namespacesArrayController arrangedObjects] count]-1;
    [_namespacesTable selectRowIndexes:[NSIndexSet indexSetWithIndex:newRow] byExtendingSelection:NO];
    [_namespacesTable editColumn:0 row:([[_namespacesArrayController arrangedObjects] count]-1) withEvent:nil select:YES];
    [dictionary release];
}

@end
