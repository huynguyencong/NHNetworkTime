

#import "NSDate+NetworkClock.h"

@implementation NSDate (NetworkClock)

- (NSTimeInterval) timeIntervalSinceNetworkDate {
  return [self timeIntervalSinceDate:[NSDate networkDate]];
}

+ (NSTimeInterval) timeIntervalSinceNetworkDate {
  return [[self date] timeIntervalSinceNetworkDate];
}


+ (NSDate *) networkDate {
  return [[NHNetworkClock sharedNetworkClock] networkTime];
}

+ (NSDate *) threadsafeNetworkDate {
  NHNetworkClock *sharedClock = [NHNetworkClock sharedNetworkClock];
  @synchronized(sharedClock) {
    return [sharedClock networkTime];
  }
}


@end