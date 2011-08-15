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

#import "ResultsTableView.h"

@implementation ResultsTableView {
	NSTrackingArea *_trackingArea;
    id _monitor;
    BOOL _mouseInside;
}

@synthesize mouseOverRow=_mouseOverRow;
@synthesize mouseOverColumn=_mouseOverColumn;

- (void)menuSelected:(NSMenuItem *)sender {
    NSPasteboard *pasteBoard = [NSPasteboard generalPasteboard];
    [pasteBoard clearContents];
    [pasteBoard setString:[sender representedObject] forType:NSStringPboardType];
}

- (NSMenu *)nameCopyMenuForUri:(NSString *)uri abbreviatedUri:(NSString *)abbreviatedUri {
    NSMenu *menu = [[NSMenu alloc] initWithTitle:@"URI Helper Menu"];
    NSMenuItem *item1 = [[NSMenuItem alloc] initWithTitle:@"Copy Fully Qualified URI" action:@selector(menuSelected:) keyEquivalent:@""];
    [item1 setRepresentedObject:uri];
    [item1 setTarget:self];
    [menu addItem:item1];
    [item1 release];
    if (![uri isEqualToString:abbreviatedUri]) {
        NSMenuItem *item2 = [[NSMenuItem alloc] initWithTitle:@"Copy Prefixed URI" action:@selector(menuSelected:) keyEquivalent:@""];
        [item2 setTarget:self];
        [item2 setRepresentedObject:abbreviatedUri];
        [menu addItem:item2];
        [item2 release];
    }
    return [menu autorelease];
}

- (void)updateCells {
	id myDelegate = [self delegate];
	if (!myDelegate) {
		return;
    }
	if (![myDelegate respondsToSelector:@selector(tableView:willDisplayCell:forTableColumn:row:)]) {
		return;
    }
    NSPoint mouseLocation = [[self window] mouseLocationOutsideOfEventStream];
    NSPoint point = [self convertPoint:mouseLocation
                              fromView:nil];
    NSInteger column = [self columnAtPoint:point];
    NSUInteger row = [self rowAtPoint:point];
    if (_mouseOverColumn != column || _mouseOverRow != row) {
        NSInteger oldRow = _mouseOverRow;
        NSInteger oldColumn = _mouseOverColumn;
        _mouseOverRow = row;
        _mouseOverColumn = column;
        NSRect cellFrame = [self frameOfCellAtColumn:oldColumn row:oldRow];
        [self setNeedsDisplayInRect:cellFrame];
        cellFrame = [self frameOfCellAtColumn:_mouseOverColumn row:_mouseOverRow];
        [self setNeedsDisplayInRect:cellFrame];
    }
}

- (void)awakeFromNib {
	[[self window] setAcceptsMouseMovedEvents:YES];
    _mouseOverColumn = -1;
    _mouseOverRow = -1;
    _trackingArea = [[NSTrackingArea alloc] initWithRect:[self visibleRect] options:NSTrackingMouseEnteredAndExited|NSTrackingMouseMoved|NSTrackingCursorUpdate|NSTrackingActiveInActiveApp|NSTrackingInVisibleRect owner:self userInfo:nil];
    [self addTrackingArea:_trackingArea];
}

- (void)dealloc {
    [NSEvent removeMonitor:_monitor];
	[self removeTrackingArea:_trackingArea];
    [_trackingArea release], _trackingArea = nil;
	[super dealloc];
}

- (void)cursorUpdate:(NSEvent *)event {
    [[NSCursor pointingHandCursor] set];
}

- (void)mouseEntered:(NSEvent *)theEvent {
    _mouseInside = YES;
    [self updateCells];
}

- (void)mouseMoved:(NSEvent *)theEvent {
    [self updateCells];
}

- (void)mouseExited:(NSEvent *)theEvent {
    [[NSCursor arrowCursor] set];
    _mouseInside = NO;
    
    NSInteger oldRow = _mouseOverRow;
    _mouseOverRow = -1;
    NSInteger oldColumn = _mouseOverColumn;
    _mouseOverColumn = -1;
    NSRect cellFrame = [self frameOfCellAtColumn:oldColumn row:oldRow];
    [self setNeedsDisplayInRect:cellFrame];
}

- (void)mouseDown:(NSEvent *)theEvent {
    [super mouseDown:theEvent];
    if (!_mouseInside) {
        return;
    }
    if (![[self delegate] conformsToProtocol:@protocol(ResultsTableViewDelegate)]) {
        return;
    }
    NSPoint point = [self convertPoint:[theEvent locationInWindow]
                              fromView:nil];
    NSInteger column = [self columnAtPoint:point];
    NSInteger row = [self rowAtPoint:point];
    
    id<ResultsTableViewDelegate> delegate = (id<ResultsTableViewDelegate>)[self delegate];
    SEL sel = @selector(tableView:menuForTableColumn:row:);
    if (column >= 0 && row >= 0 && [delegate respondsToSelector:sel]) {
        NSMenu *menu = [delegate tableView:self menuForTableColumn:column row:row];
        if (menu && [[menu itemArray] count] > 0) {
            [menu popUpMenuPositioningItem:[menu itemAtIndex:0] atLocation:point inView:self];
        }
    }
}

@end
