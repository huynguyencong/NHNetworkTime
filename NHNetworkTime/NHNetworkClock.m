#import <arpa/inet.h>

#import "NHNetworkClock.h"
#import "NHNTLog.h"

@interface NHNetworkClock () <NHNetAssociationDelegate> {

    NSMutableArray *        timeAssociations;
    NSArray *               sortDescriptors;

    NSSortDescriptor *      dispersionSortDescriptor;
    dispatch_queue_t        associationDelegateQueue;
    
}

@end

#pragma mark -
#pragma mark                        N E T W O R K • C L O C K

@implementation NHNetworkClock

+ (instancetype) sharedNetworkClock {
    static id               sharedNetworkClockInstance = nil;
    static dispatch_once_t  onceToken;

    dispatch_once(&onceToken, ^{
        sharedNetworkClockInstance = [[self alloc] init];
    });

    return sharedNetworkClockInstance;
}

- (instancetype) init {
    if (self = [super init]) {
        sortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:@"dispersion" ascending:YES]];
        timeAssociations = [NSMutableArray arrayWithCapacity:100];
        
        [[[NSOperationQueue alloc] init] addOperation:[[NSInvocationOperation alloc]
                                                       initWithTarget:self
                                                       selector:@selector(createAssociations)
                                                       object:nil]];
    }
    
    return self;
}

// Return the offset to network-derived UTC.

- (NSTimeInterval) networkOffset {

    if ([timeAssociations count] == 0) return 0.0;
    
    NSArray *       sortedArray = [timeAssociations sortedArrayUsingDescriptors:sortDescriptors];

    double          timeInterval = 0.0;
    short           usefulCount = 0;
    
    for (NHNetAssociation * timeAssociation in sortedArray) {
        if (timeAssociation.active) {
            if (timeAssociation.trusty) {
                usefulCount++;
                timeInterval = timeInterval + timeAssociation.offset;
            }
            else {
                NSLog(@"Clock•Drop: [%@]", timeAssociation.server);
                if ([timeAssociations count] > 8) {
                    [timeAssociations removeObject:timeAssociation];
                    [timeAssociation finish];
                }
            }
            
            if (usefulCount == 8) break;                // use 8 best dispersions
        }
    }
    
    if (usefulCount > 0) {
        timeInterval = timeInterval / usefulCount;
    }

    return timeInterval;
}

- (NSDate *) networkTime {
    return [[NSDate date] dateByAddingTimeInterval:-[self networkOffset]];
}

// Use the following time servers or, if it exists, read the "ntp.hosts" file from the application resources and derive all the IP addresses referred to, remove any duplicates and create an 'association' (individual host client) for each one.

- (void) createAssociations {
    NSArray *           ntpDomains;
    NSString *          filePath = [[NSBundle mainBundle] pathForResource:@"ntp.hosts" ofType:@""];
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
        NSString *      fileData = [[NSString alloc] initWithData:[[NSFileManager defaultManager]
                                                                   contentsAtPath:filePath]
                                                         encoding:NSUTF8StringEncoding];

        ntpDomains = [fileData componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    }

    // for each NTP service domain name in the 'ntp.hosts' file : "0.pool.ntp.org" etc ...
    NSMutableSet *      hostAddresses = [NSMutableSet setWithCapacity:100];

    for (NSString * ntpDomainName in ntpDomains) {
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

        Boolean         nameFound;
        CFArrayRef      ntpHostAddrs = CFHostGetAddressing (ntpHostName, &nameFound);

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
        for (NSData * ntpHost in (__bridge NSArray *)ntpHostAddrs) {
            [hostAddresses addObject:[GCDAsyncUdpSocket hostFromAddress:ntpHost]];
        }

        CFRelease(ntpHostName);
    }

    NTP_Logging(@"%@", hostAddresses);                          // all the addresses resolved

    // ... now start one 'association' (network clock server) for each address.
    for (NSString * server in hostAddresses) {
        NHNetAssociation *    timeAssociation = [[NHNetAssociation alloc] initWithServerName:server];
        timeAssociation.delegate = self;

        [timeAssociations addObject:timeAssociation];
        [timeAssociation enable];                               // starts are randomized internally
    }
}

// Stop all the individual ntp clients associations ..
- (void) finishAssociations {
    for (NHNetAssociation * timeAssociation in timeAssociations) {
        timeAssociation.delegate = nil;
        [timeAssociation finish];
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)netAssociationDidFinishGetTime:(NHNetAssociation *)netAssociation {
    NSLog(@"huync - %s - %d, %@, %lf", __PRETTY_FUNCTION__, netAssociation.trusty, netAssociation.server, netAssociation.offset);
}

#pragma mark -
#pragma mark                        I n t e r n a l  •  M e t h o d s

@end
