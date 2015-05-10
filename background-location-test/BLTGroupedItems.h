//
//  BLTTripGroups.h
//  background-location-test
//
//  Created by Brian Dewey on 4/12/15.
//  Copyright (c) 2015 Brian's Brain. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BLTTrip;

@protocol BLTGroupedItemsDelegate;

@interface BLTGroupedItems : NSObject <NSSecureCoding>

@property (nonatomic, readonly, assign) NSUInteger countOfGroups;
@property (nonatomic, readonly, weak) id<BLTGroupedItemsDelegate> delegate;

- (instancetype)initWithDelegate:(id<BLTGroupedItemsDelegate>)delegate;

- (NSString *)nameOfGroup:(NSUInteger)indexOfTripGroup;
- (NSUInteger)countOfItemsInGroup:(NSUInteger)indexOfTripGroup;
- (id<NSSecureCoding>)itemForIndexPath:(NSIndexPath *)indexPath;

// BLTGroupedItems is an immutable container. Right now it's an inefficient implementation.
- (BLTGroupedItems *)groupedItemsByAddingItem:(id<NSSecureCoding>)item;

@end

@protocol BLTGroupedItemsDelegate <NSObject>

- (NSString *)groupedItems:(BLTGroupedItems *)groupedItems nameOfGroupForItem:(id<NSSecureCoding>)item;
- (BOOL)groupedItemsDisplayInReversedOrder:(BLTGroupedItems *)groupedItems;

@end