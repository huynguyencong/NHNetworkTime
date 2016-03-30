#import <arpa/inet.h>

#import "NHNetworkClock.h"
#import "NHNTLog.h"

#define kTimeOffsetKey @"kTimeOffsetKey"

@interface NHNetworkClock () <NHNetAssociationDelegate>

@property NSMutableArray *timeAssociations;
@property NSArray *sortDescriptors;
@property NSSortDescriptor *dispersionSortDescriptor;
@property dispatch_queue_t associationDelegateQueue;
@property (readwrite) BOOL isSynchronized;

@end

@implementation NHNetworkClock

+ (instancetype)sharedNetworkClock {
    static id sharedNetworkClockInstance = nil;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        sharedNetworkClockInstance = [[self alloc] init];
    });

    return sharedNetworkClockInstance;
}

- (instancetype)init {
    if (self = [super init]) {
        self.sortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:@"dispersion" ascending:YES]];
        self.timeAssociations = [NSMutableArray arrayWithCapacity:100];
        self.shouldUseSavedSynchronizedTime = YES;
        self.isAutoSynchronizedWhenUserChangeLocalTime = YES;
        
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationSignificantTimeChangeNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
            if(self.isAutoSynchronizedWhenUserChangeLocalTime) {
                [self synchronize];
            }
        }];
    }
    
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)reset {
    self.isSynchronized = NO;
    [self finishAssociations];
    [self.timeAssociations removeAllObjects];
}

// Return the offset to network-derived UTC.

- (NSTimeInterval)networkOffset {
    
    double timeInterval = 0.0;
    short usefulCount = 0;
    
    if(self.timeAssociations.count > 0) {
    
        NSArray *sortedArray = [[self.timeAssociations sortedArrayUsingDescriptors:self.sortDescriptors] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id  _Nonnull evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
            return [evaluatedObject isKindOfClass:[NHNetAssociation class]];
        }]];
        
        for (NHNetAssociation * timeAssociation in sortedArray) {
            if (timeAssociation.active) {
                if (timeAssociation.trusty) {
                    usefulCount++;
                    timeInterval = timeInterval + timeAssociation.offset;
                }
                else {
                    if ([self.timeAssociations count] > 8) {
                        [self.timeAssociations removeObject:timeAssociation];
                        [timeAssociation finish];
                    }
                }
                
                if (usefulCount == 8) break;                // use 8 best dispersions
            }
        }
    }
    
    if (usefulCount > 0) {
        timeInterval = timeInterval / usefulCount;
    }
    else {
        if(self.shouldUseSavedSynchronizedTime) {
            timeInterval = [[NSUserDefaults standardUserDefaults] doubleForKey:kTimeOffsetKey];
        }
    }

    return timeInterval;
}

#pragma mark - Get time

- (NSDate *)networkTime {
    return [[NSDate date] dateByAddingTimeInterval:-[self networkOffset]];
}

#pragma mark - Associations

// Use the following time servers or, if it exists, read the "ntp.hosts" file from the application resources and derive all the IP addresses referred to, remove any duplicates and create an 'association' (individual host client) for each one.

- (void)createAssociations {
    NSArray *ntpDomains;
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"ntp.hosts" ofType:@""];
    if (nil == filePath) {
        ntpDomains = @[@"0.pool.ntp.org",
                       @"0.uk.pool.ntp.org",
                       @"0.us.pool.ntp.org",
                       @"asia.pool.ntp.org",
                       @"europe.pool.ntp.org",
                       @"north-america.pool.ntp.org",
                       @"south-america.pool.ntp.org",
                       @"oceania.pool.ntp.org",
                       @"africa.pool.ntp.org"];
    }
    else {
        NSString *fileData = [[NSString alloc] initWithData:[[NSFileManager defaultManager]
                                                                   contentsAtPath:filePath]
                                                         encoding:NSUTF8StringEncoding];

        ntpDomains = [fileData componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    }

    // for each NTP service domain name in the 'ntp.hosts' file : "0.pool.ntp.org" etc ...
    NSMutableSet *hostAddresses = [NSMutableSet setWithCapacity:100];

    for (NSString *ntpDomainName in ntpDomains) {
        if ([ntpDomainName length] == 0 ||
            [ntpDomainName characterAtIndex:0] == ' ' ||
            [ntpDomainName characterAtIndex:0] == '#') {
            continue;
        }

        // ... resolve the IP address of the named host : "0.pool.ntp.org" --> [123.45.67.89], ...
        CFHostRef ntpHostName = CFHostCreateWithName (nil, (__bridge CFStringRef)ntpDomainName);
        if (nil == ntpHostName) {
            NTP_Logging(@"CFHostCreateWithName <nil> for %@", ntpDomainName);
            continue;                                           // couldn't create 'host object' ...
        }

        CFStreamError   nameError;
        if (!CFHostStartInfoResolution (ntpHostName, kCFHostAddresses, &nameError)) {
            NTP_Logging(@"CFHostStartInfoResolution error %i for %@", (int)nameError.error, ntpDomainName);
            CFRelease(ntpHostName);
            continue;                                           // couldn't start resolution ...
        }

        Boolean nameFound;
        CFArrayRef ntpHostAddrs = CFHostGetAddressing (ntpHostName, &nameFound);

        if (!nameFound) {
            NTP_Logging(@"CFHostGetAddressing: %@ NOT resolved", ntpHostName);
            CFRelease(ntpHostName);
            continue;                                           // resolution failed ...
        }

        if (ntpHostAddrs == nil) {
            NTP_Logging(@"CFHostGetAddressing: no addresses resolved for %@", ntpHostName);
            CFRelease(ntpHostName);
            continue;                                           // NO addresses were resolved ...
        }
        //for each (sockaddr structure wrapped by a CFDataRef/NSData *) associated with the hostname, drop the IP address string into a Set to remove duplicates.
        for (NSData *ntpHost in (__bridge NSArray *)ntpHostAddrs) {
            [hostAddresses addObject:[GCDAsyncUdpSocket hostFromAddress:ntpHost]];
        }

        CFRelease(ntpHostName);
    }

    NTP_Logging(@"%@", hostAddresses);                          // all the addresses resolved

    // ... now start one 'association' (network clock server) for each address.
    for (NSString *server in hostAddresses) {
        NHNetAssociation *    timeAssociation = [[NHNetAssociation alloc] initWithServerName:server];
        timeAssociation.delegate = self;

        [self.timeAssociations addObject:timeAssociation];
        [timeAssociation enable];                               // starts are randomized internally
    }
}

// Stop all the individual ntp clients associations ..

- (void)finishAssociations {
    NSArray *timeAssociationsCopied = [self.timeAssociations copy];
    for (NHNetAssociation * timeAssociation in timeAssociationsCopied) {
        timeAssociation.delegate = nil;
        [timeAssociation finish];
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Sync

- (void)synchronize {
    [self reset];
    
    [[[NSOperationQueue alloc] init] addOperation:[[NSInvocationOperation alloc]
                                                   initWithTarget:self
                                                   selector:@selector(createAssociations)
                                                   object:nil]];
}

#pragma mark - NHNetAssociationDelegate

- (void)netAssociationDidFinishGetTime:(NHNetAssociation *)netAssociation {
    if(netAssociation.active && netAssociation.trusty) {
        
        [[NSUserDefaults standardUserDefaults] setDouble:netAssociation.offset forKey:kTimeOffsetKey];
        
        if (self.isSynchronized == NO) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kNHNetworkTimeSyncCompleteNotification object:nil userInfo:nil];
            self.isSynchronized = YES;
        }
    }
}

@end
