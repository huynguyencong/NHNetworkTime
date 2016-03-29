/**
 NHNetworkClock.h
 Created by Gavin Eadie on Oct17/10 ... Copyright 2010-14 Ramsay Consulting. All rights reserved.
 Modified by Nguyen Cong Huy on 9 Sep 2015
 */

#import "NHNetAssociation.h"

#define kNHNetworkTimeSyncCompleteNotification @"kNHNetworkTimeSyncCompleteNotification"

// The NetworkClock sends notifications of the network time.  It will attempt to provide a very early estimate and then refine that and reduce the number of notifications ...
// NetworkClock is a singleton class which will provide the best estimate of the difference in time between the device's system clock and the time returned by a collection of time servers. The method <networkTime> returns an NSDate with the network time.

@interface NHNetworkClock : NSObject

@property (nonatomic, readonly, copy) NSDate *networkTime;
@property (nonatomic, readonly) NSTimeInterval networkOffset;
@property (nonatomic, readonly) BOOL isSynchronized;

#pragma mark - Options

// every time network time is synchronized with server, it will be saved to disk. When call sync function (synchronize), if this property set to YES, it will use the previous saved time, before receive synchronized time from server. Default is YES
@property (nonatomic) BOOL shouldUseSavedSynchronizedTime;

// synchronize if user change local time
@property (nonatomic) BOOL isAutoSynchronizedWhenUserChangeLocalTime;

#pragma mark -

+ (instancetype) sharedNetworkClock;

- (void)synchronize;

@end