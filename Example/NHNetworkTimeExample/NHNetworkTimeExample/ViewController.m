//
//  ViewController.m
//  NHNetworkTimeExample
//
//  Created by Nguyen Cong Huy on 9/20/15.
//  Copyright © 2015 Nguyen Cong Huy. All rights reserved.
//

#import "ViewController.h"
#import "NHNetworkTime.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UILabel *currentLabel;
@property (weak, nonatomic) IBOutlet UILabel *networkLabel;
@property (weak, nonatomic) IBOutlet UILabel *syncedLabel;

@property (nonatomic) NSTimer *oneSecondTimer;

@end

@implementation ViewController

- (instancetype)init {
    if(self = [super init]) {
        
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self updateDateToLabel];
    [self observeTimeSyncNotification];
    [self createUpdateUITimer];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.oneSecondTimer invalidate];
}

#pragma mark - Notification

- (void)observeTimeSyncNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkTimeSyncCompleteNotification:) name:kNHNetworkTimeSyncCompleteNotification object:nil];
}

- (void)networkTimeSyncCompleteNotification:(NSNotification *)notification {
    [self updateDateToLabel];
}

#pragma mark - Update label timer

- (void)createUpdateUITimer {
    self.oneSecondTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(oneSecondTimerTick) userInfo:nil repeats:YES];
}

- (void)oneSecondTimerTick {
    [self updateDateToLabel];
}

#pragma mark - UI

- (void)updateDateToLabel {
    NSString *currentLabelText = [NSString stringWithFormat:@"%@", [NSDate date]];
    NSString *networkLabelText = [NSString stringWithFormat:@"%@", [NSDate networkDate]];
    
    self.currentLabel.text = currentLabelText;
    self.networkLabel.text = networkLabelText;
    
    if([NHNetworkClock sharedNetworkClock].isSynchronized) {
        self.syncedLabel.text = @"Time is SYNCHRONIZED";
        self.syncedLabel.textColor = [UIColor blueColor];
    }
    else {
        self.syncedLabel.text = @"Time is NOT synchronized";
        self.syncedLabel.textColor = [UIColor redColor];
    }
}

@end
