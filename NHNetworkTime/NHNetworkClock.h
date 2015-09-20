/**
 NHNetworkClock.h
 Created by Gavin Eadie on Oct17/10 ... Copyright 2010-14 Ramsay Consulting. All rights reserved.
 Modified by Nguyen Cong Huy on 9 Sep 2015
 */

#import "NHNetAssociation.h"

// The NetworkClock sends notifications of the network time.  It will attempt to provide a very early estimate and then refine that and reduce the number of notifications ...
// NetworkClock is a singleton class which will provide the best estimate of the difference in time between the device's system clock and the time returned by a collection of time servers. The method <networkTime> returns an NSDate with the network time.

@interface NHNetworkClock : NSObject

+ (instancetype) sharedNetworkClock;

- (void) createAssociations;
- (void) finishAssociations;

//Return the device clock time adjusted for the offset to network-derived UTC.
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSDate *   networkTime;
@property (NS_NONATOMIC_IOSONLY, readonly) NSTimeInterval   networkOffset;

@end