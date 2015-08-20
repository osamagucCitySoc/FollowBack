//
//  AccountChooserTableViewController.m
//  FollowBack
//
//  Created by Osama Rabie on 8/20/15.
//  Copyright (c) 2015 Osama Rabie. All rights reserved.
//

#import "AccountChooserTableViewController.h"
#import <Social/Social.h>
#import <Accounts/Accounts.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import "ViewController.h"

@interface AccountChooserTableViewController ()

@end

@implementation AccountChooserTableViewController
{
    NSArray* dataSource;
    __weak IBOutlet UIView *myBanner;
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([[segue identifier]isEqualToString:@"startSeg"])
    {
        ViewController* dst = (ViewController*)[segue destinationViewController];
        [dst setSelectedAccount:[dataSource objectAtIndex:self.tableView.indexPathForSelectedRow.row]];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    ACAccountStore *accountStore = [[ACAccountStore alloc] init];
    ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    
    [accountStore requestAccessToAccountsWithType:accountType options:nil completion:^(BOOL granted, NSError *error){
        if (granted) {
            
            dataSource = [accountStore accountsWithAccountType:accountType];

            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
                [self.tableView setNeedsDisplay];
            });
            
        } else {
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"عفواً" message:@"لكي تستطيع التعامل من خلال التطبيق يجب أن تسمح لنا بإستعمال حساباتك" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            dispatch_async(dispatch_get_main_queue(), ^{
                [alert show];
            });
        }
    }];
    
    GADBannerView* bannerVieww = [[GADBannerView alloc]initWithAdSize:kGADAdSizeMediumRectangle];
    
    [bannerVieww setFrame:CGRectMake(0, 0, 320, 250)];
    
    bannerVieww.adUnitID = @"ca-app-pub-2433238124854818/6548082790";
    bannerVieww.rootViewController = self;
    
    GADRequest *request = [GADRequest request];
    
    
    request.testDevices = @[@"kGADSimulatorID",@"39d58745fe9b0532c8ee4722934037f7"];
    
    [bannerVieww loadRequest:request];
    
    [myBanner addSubview:bannerVieww];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return dataSource.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString* cellID = @"accountCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID forIndexPath:indexPath];
    if(!cell)
    {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
    }
    
    [[cell textLabel]setText:[[dataSource objectAtIndex:indexPath.row] username]];
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self performSegueWithIdentifier:@"startSeg" sender:self];
}

@end
