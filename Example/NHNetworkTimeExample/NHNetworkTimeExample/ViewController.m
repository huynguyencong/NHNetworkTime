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

@end

@implementation ViewController

- (instancetype)init {
    if(self = [super init]) {
        
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self updateDate];
}


- (IBAction)getNetworkTimeTouched:(id)sender {
    [self updateDate];
}

- (void)updateDate {
    NSString *currentLabelText = [NSString stringWithFormat:@"Current: %@", [NSDate date]];
    NSString *networkLabelText = [NSString stringWithFormat:@"Network: %@", [NSDate networkDate]];
    
    self.currentLabel.text = currentLabelText;
    self.networkLabel.text = networkLabelText;
    
    if([NHNetworkClock sharedNetworkClock].isSynchronized) {
        self.syncedLabel.text = @"Time is SYNCHRONIZED";
    }
    else {
        self.syncedLabel.text = @"Time is NOT synchronized";
    }
}

@end
