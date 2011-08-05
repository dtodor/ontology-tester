//
//  NSTableView+TDExtensions.m
//  Ontology Tester
//
//  Created by Todor Dimitrov on 8/5/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NSTableView+TDExtensions.h"

@implementation NSTableView (TDExtensions)

- (NSMenu *)menuForEvent:(NSEvent *)evt {
    NSPoint point = [self convertPoint:[evt locationInWindow]
                              fromView:NULL];
    NSInteger columnIndex = [self columnAtPoint:point];
    NSInteger rowIndex = [self rowAtPoint:point];
    if ([[self delegate] conformsToProtocol:@protocol(TDTableViewDelegate)]) {
        id<TDTableViewDelegate> delegate = (id<TDTableViewDelegate>)[self delegate];
        SEL sel = @selector(tableView:menuForTableColumn:row:);
        if (columnIndex >= 0 && rowIndex >= 0 && [delegate respondsToSelector:sel]) {
            return [delegate tableView:self menuForTableColumn:columnIndex row:rowIndex];
        }
    }
    return NULL;
}

- (void)menuSelected:(NSMenuItem *)sender {
    NSPasteboard *pasteBoard = [NSPasteboard generalPasteboard];
    [pasteBoard clearContents];
    [pasteBoard setString:[sender representedObject] forType:NSStringPboardType];
}

- (NSMenu *)nameCopyMenuForUri:(NSString *)uri abbreviatedUri:(NSString *)abbreviatedUri {
    NSMenu *menu = [[NSMenu alloc] initWithTitle:@"Hallo"];
    NSMenuItem *item1 = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"Copy '%@'", uri] action:@selector(menuSelected:) keyEquivalent:@""];
    [item1 setRepresentedObject:uri];
    [item1 setTarget:self];
    [menu addItem:item1];
    [item1 release];
    if (![uri isEqualToString:abbreviatedUri]) {
        NSMenuItem *item2 = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"Copy '%@'", abbreviatedUri] action:@selector(menuSelected:) keyEquivalent:@""];
        [item2 setTarget:self];
        [item2 setRepresentedObject:abbreviatedUri];
        [menu addItem:item2];
        [item2 release];
    }
    return [menu autorelease];
}

@end
