//
//  NSTableView+TDExtensions.h
//  Ontology Tester
//
//  Created by Todor Dimitrov on 8/5/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol TDTableViewDelegate <NSTableViewDelegate>

@optional
- (NSMenu *)tableView:(NSTableView *)tableView menuForTableColumn:(NSInteger)column row:(NSInteger)row;

@end

@interface NSTableView (TDExtensions)

- (NSMenu *)nameCopyMenuForUri:(NSString *)uri abbreviatedUri:(NSString *)abbreviatedUri;

@end
