//
//  ViewController.m
//  FollowBack
//
//  Created by Osama Rabie on 8/20/15.
//  Copyright (c) 2015 Osama Rabie. All rights reserved.
//

#import "ViewController.h"
#import "AsyncImageView.h"
#import <GoogleMobileAds/GoogleMobileAds.h>

@interface ViewController ()

@end

@implementation ViewController
{
    __weak IBOutlet AsyncImageView *friendImage;
    __weak IBOutlet UILabel *friendUserNameLabel;
    __weak IBOutlet UIView *myBanner;
}

@synthesize  selectedAccount;

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setTitle:[NSString stringWithFormat:@"%@%@",@"@",selectedAccount.username]];

    GADBannerView* bannerVieww = [[GADBannerView alloc]initWithAdSize:kGADAdSizeMediumRectangle];
    
    
    bannerVieww.adUnitID = @"ca-app-pub-2433238124854818/6548082790";
    bannerVieww.rootViewController = self;

    GADRequest *request = [GADRequest request];
    
    
    request.testDevices = @[@"kGADSimulatorID",@"39d58745fe9b0532c8ee4722934037f7"];
    
    [bannerVieww loadRequest:request];
    
    [myBanner addSubview:bannerVieww];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)skipButtonClicked:(id)sender {
}
- (IBAction)followButtonClicked:(id)sender {
}

@end
