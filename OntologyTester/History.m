//
//  History.m
//  Ontology Tester
//
//  Created by Todor Dimitrov on 8/13/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "History.h"


#define HISTORY_SIZE 10


@interface HistoryItem()

+ (HistoryItem *)historyItemWithSubject:(NSString *)subject
                              subjectNS:(NSString *)subjectNS
                              predicate:(NSString *)predicate
                            predicateNS:(NSString *)predicateNS
                                 object:(NSString *)object
                               objectNS:(NSString *)objectNS;

@end


@implementation HistoryItem

@synthesize subject=_subject;
@synthesize subjectNS=_subjectNS;
@synthesize predicate=_predicate;
@synthesize predicateNS=_predicateNS;
@synthesize object=_object;
@synthesize objectNS=_objectNS;

+ (HistoryItem *)historyItemWithSubject:(NSString *)subject 
                              subjectNS:(NSString *)subjectNS
                              predicate:(NSString *)predicate
                            predicateNS:(NSString *)predicateNS
                                 object:(NSString *)object
                               objectNS:(NSString *)objectNS {
    

    HistoryItem *item = [[[HistoryItem alloc] init] autorelease];
    if (item) {
        item->_subject = [subject copy];
        item->_subjectNS = [subjectNS copy];
        item->_predicate = [predicate copy];
        item->_predicateNS = [predicateNS copy];
        item->_object = [object copy];
        item->_objectNS = [objectNS copy];
    }
    return item;
}

- (void)dealloc {
    [_subject release], _subject = nil;
    [_subjectNS release], _subjectNS = nil;
    [_predicate release], _predicate = nil;
    [_predicateNS release], _predicateNS = nil;
    [_object release], _object = nil;
    [_objectNS release], _objectNS = nil;
    [super dealloc];
}

@end


@interface History()

@property (nonatomic) BOOL canGoBack;
@property (nonatomic) BOOL canGoForward;

@end


@implementation History {
    NSMutableArray *_items;
    NSUInteger _currentPosition;
}

@synthesize canGoBack=_canGoBack;
@synthesize canGoForward=_canGoForward;

- (id)init {
    self = [super init];
    if (self) {
        _items = [[NSMutableArray alloc] init];
        self.canGoBack = NO;
        self.canGoForward = NO;
    }
    return self;
}

- (void)dealloc {
    [_items release], _items = nil;
    [super dealloc];
}

- (void)updateState {
    self.canGoBack = _currentPosition >= 1;
    self.canGoForward = _currentPosition < [_items count]-1;
}

- (HistoryItem *)goBack {
    if ([_items count] < 1 || _currentPosition < 1) {
        return nil;
    }
    _currentPosition--;
    [self updateState];
    return [_items objectAtIndex:_currentPosition];
}

- (HistoryItem *)goForward {
    NSUInteger count = [_items count];
    if (count < 1 || _currentPosition == count-1) {
        return nil;
    }
    _currentPosition++;
    [self updateState];
    return [_items objectAtIndex:_currentPosition];
}

- (void)addToHistoryWithSubject:(NSString *)subject
                      subjectNS:(NSString *)subjectNS
                      predicate:(NSString *)predicate
                    predicateNS:(NSString *)predicateNS
                         object:(NSString *)object
                       objectNS:(NSString *)objectNS {
    
    HistoryItem *item = [HistoryItem historyItemWithSubject:subject 
                                                  subjectNS:subjectNS 
                                                  predicate:predicate 
                                                predicateNS:predicateNS 
                                                     object:object 
                                                   objectNS:objectNS];
    NSUInteger count = [_items count];
    if (count > 0) {
        if (count == HISTORY_SIZE) {
            [_items removeObjectAtIndex:0];
        }
        _currentPosition = count;
    }
    [_items addObject:item];
    [self updateState];
}

@end
