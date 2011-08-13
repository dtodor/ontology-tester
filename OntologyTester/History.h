//
//  History.h
//  Ontology Tester
//
//  Created by Todor Dimitrov on 8/13/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HistoryItem : NSObject

@property (nonatomic, readonly) NSString *subjectNS;
@property (nonatomic, readonly) NSString *subject;
@property (nonatomic, readonly) NSString *predicateNS;
@property (nonatomic, readonly) NSString *predicate;
@property (nonatomic, readonly) NSString *objectNS;
@property (nonatomic, readonly) NSString *object;

@end

@interface History : NSObject

@property (nonatomic, readonly) BOOL canGoBack;
@property (nonatomic, readonly) BOOL canGoForward;

- (HistoryItem *)goBack;
- (HistoryItem *)goForward;

- (void)addToHistoryWithSubject:(NSString *)subject
                      subjectNS:(NSString *)subjectNS
                      predicate:(NSString *)predicate
                    predicateNS:(NSString *)predicateNS
                         object:(NSString *)object
                       objectNS:(NSString *)objectNS;

@end
