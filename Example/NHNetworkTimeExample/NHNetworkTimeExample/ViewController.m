//
//  ViewController.m
//  NHNetworkTimeExample
//
//  Created by Nguyen Cong Huy on 9/20/15.
//  Copyright © 2015 Nguyen Cong Huy. All rights reserved.
//

#import "ViewController.h"
#import "ios-ntp.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UILabel *currentLabel;
@property (weak, nonatomic) IBOutlet UILabel *networkLabel;

@end

@implementation ViewController

- (instancetype)init {
    if(self = [super init]) {
        
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}


- (IBAction)getNetworkTimeTouched:(id)sender {
    NSString *currentLabelText = [NSString stringWithFormat:@"Current: %@", [NSDate date]];
    NSString *networkLabelText = [NSString stringWithFormat:@"Network: %@", [NSDate networkDate]];
    
    self.currentLabel.text = currentLabelText;
    self.networkLabel.text = networkLabelText;
}

@end
