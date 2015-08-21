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
#import "STTwitter.h"
#import <Twitter/Twitter.h>
#import "UICKeyChainStore.h"


@interface ViewController ()<GADInterstitialDelegate>

@property (strong, nonatomic) GADInterstitial *interstitial_;

@end

@implementation ViewController
{
    __weak IBOutlet AsyncImageView *friendImage;
    __weak IBOutlet UILabel *friendUserNameLabel;
    __weak IBOutlet UIView *myBanner;
    __weak IBOutlet UIActivityIndicatorView *loader;
    NSString* currentFriendName;
    NSString* currentFriendAccess;
    NSString* currentFriendSecret;
    NSString* currentFriendTwitterAccess;
    NSString* currentFriendTwitterSecret;
    NSString* currentFriendID;
    NSString* currentFriendImage;
    STTwitterAPI* twitter;
}

@synthesize  selectedAccount;

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setTitle:[NSString stringWithFormat:@"%@%@",@"@",selectedAccount.username]];
    
    GADBannerView* bannerVieww = [[GADBannerView alloc]initWithAdSize:kGADAdSizeMediumRectangle];
    
    
    bannerVieww.adUnitID = @"ca-app-pub-2433238124854818/5132591591";
    bannerVieww.rootViewController = self;
    
    GADRequest *request = [GADRequest request];
    
    
    request.testDevices = @[@"kGADSimulatorID",@"39d58745fe9b0532c8ee4722934037f7"];
    
    [bannerVieww loadRequest:request];
    
    [myBanner addSubview:bannerVieww];
    
    [loader setAlpha:1.0];
    
    [self getSources];
    
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    UICKeyChainStore* store = [UICKeyChainStore keyChainStore];
    
    @try
    {
        if(![store stringForKey:@"follow"])
        {
            [store setString:@"0" forKey:@"follow"];
            [store synchronize];
        }
    } @catch (NSException *exception) {
        [store setString:@"0" forKey:@"follow"];
        [store synchronize];
    }
    
    @try
    {
        if([store stringForKey:@"lastFollow"])
        {
            long diff = NSTimeIntervalSince1970-[[store stringForKey:@"lastFollow"] longLongValue];
            if(diff >= 3600)
            {
                [store setString:@"0" forKey:@"follow"];
                [store synchronize];
                [[UIApplication sharedApplication] cancelAllLocalNotifications];
            }
        }
    } @catch (NSException *exception) {
        [store setString:@"0" forKey:@"follow"];
        [store synchronize];
    }
    
  }

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)skipButtonClicked:(id)sender {
    [self getNewFriend];
}
- (IBAction)followButtonClicked:(id)sender {
    UICKeyChainStore* store = [UICKeyChainStore keyChainStore];
    
    BOOL follow = NO;
    
    @try
    {
        if([[store stringForKey:@"follow"] intValue]<50)
        {
            follow = YES;
        }else
        {
            follow = YES;
        }
    } @catch (NSException *exception) {
        follow = YES;
    }
    
    
    if(follow)
    {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            [loader setAlpha:1.0];
        });
        
        [twitter postFriendshipsCreateForScreenName:[selectedAccount username] orUserID:nil successBlock:^(NSDictionary* frd)
         {
             SLRequest *requestt = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:SLRequestMethodPOST URL:[NSURL URLWithString:@"https://api.twitter.com/1.1/friendships/create.json"] parameters:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:currentFriendName, @"false", nil] forKeys:[NSArray arrayWithObjects:@"screen_name", @"follow", nil]]];
             [requestt setAccount:selectedAccount];
             [requestt performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error){
                 
                 if([[store stringForKey:@"follow"] intValue] > 0 && [[store stringForKey:@"follow"] intValue]%11 == 0)
                 {
                     self.interstitial_ = [[GADInterstitial alloc] initWithAdUnitID:@"ca-app-pub-2433238124854818/8086057994"];
                     self.interstitial_.delegate = self;
                     [self.interstitial_ loadRequest:[GADRequest request]];
                 }
                 
                 if(NSTimeIntervalSince1970 - [[store stringForKey:@"lastFollow"] longLongValue] >= 3600)
                 {
                     [store setString:@"1" forKey:@"follow"];
                     [store setString:[NSString stringWithFormat:@"%f",NSTimeIntervalSince1970] forKey:@"lastFollow"];
                     [store synchronize];
                     [[UIApplication sharedApplication] cancelAllLocalNotifications];
                 }else
                 {
                     [store setString:[NSString stringWithFormat:@"%i",[[store stringForKey:@"follow"] intValue]+1] forKey:@"follow"];
                     [store setString:[NSString stringWithFormat:@"%f",NSTimeIntervalSince1970] forKey:@"lastFollow"];
                     [store synchronize];
                 }
                 
                [self getNewFriend];
                 
             }];
         }errorBlock:^(NSError *error) {
             [self getNewFriend];
         }];
    }else
    {
        UIAlertView* alert = [[UIAlertView alloc]initWithTitle:@"عفواً" message:@"لقد تجاوزت الحد المسموح به خلال الساعة الواحدة.\nسيتم تنبيهك عند فتح الفولو لك بعد قليل" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        long stillToWait = 3600 - (NSTimeIntervalSince1970 - [[store stringForKey:@"lastFollow"] longLongValue]);
        UILocalNotification* localNotification = [[UILocalNotification alloc] init];
        localNotification.fireDate = [NSDate dateWithTimeIntervalSinceNow:stillToWait];
        localNotification.alertBody = @"عد لنا الأن!! تم رفع الليمت عنك، ألاف الحسابات الجديدة في إنتظارك";
        localNotification.timeZone = [NSTimeZone defaultTimeZone];
        [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
        
        [self.navigationController popViewControllerAnimated:YES];
    }
}


#pragma mark server methods
-(void)getSources
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData* data = [[NSData alloc]initWithContentsOfURL:[NSURL URLWithString:@"http://osamalogician.com/arabDevs/FollowBack/getSources.php"]];
        NSString* encryptedSources = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
        
        // 1--20
        
        NSString* ch1 = [encryptedSources substringWithRange:NSMakeRange(1, 1)];
        NSString* ch2 = [encryptedSources substringWithRange:NSMakeRange(20, 1)];
        encryptedSources = [encryptedSources stringByReplacingCharactersInRange:NSMakeRange(1, 1) withString:ch2];
        encryptedSources = [encryptedSources stringByReplacingCharactersInRange:NSMakeRange(20, 1) withString:ch1];
        
        // 10--19
        
        ch1 = [encryptedSources substringWithRange:NSMakeRange(10, 1)];
        ch2 = [encryptedSources substringWithRange:NSMakeRange(19, 1)];
        encryptedSources = [encryptedSources stringByReplacingCharactersInRange:NSMakeRange(10, 1) withString:ch2];
        encryptedSources = [encryptedSources stringByReplacingCharactersInRange:NSMakeRange(19, 1) withString:ch1];
        
        // 4--8
        
        ch1 = [encryptedSources substringWithRange:NSMakeRange(4, 1)];
        ch2 = [encryptedSources substringWithRange:NSMakeRange(8, 1)];
        encryptedSources = [encryptedSources stringByReplacingCharactersInRange:NSMakeRange(4, 1) withString:ch2];
        encryptedSources = [encryptedSources stringByReplacingCharactersInRange:NSMakeRange(8, 1) withString:ch1];
        
        // Reverse
        
        NSMutableString *reversedString = [NSMutableString stringWithCapacity:[encryptedSources length]];
        
        [encryptedSources enumerateSubstringsInRange:NSMakeRange(0,[encryptedSources length])
                                             options:(NSStringEnumerationReverse | NSStringEnumerationByComposedCharacterSequences)
                                          usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
                                              [reversedString appendString:substring];
                                          }];
        
        
        reversedString = (NSMutableString*) [reversedString substringToIndex:reversedString.length-1];
        
        
        NSData *decodedData = [[NSData alloc] initWithBase64EncodedString:reversedString options:0];
        NSString *decodedString = [[NSString alloc] initWithData:decodedData encoding:NSUTF8StringEncoding];

        
        NSArray* sources = [decodedString componentsSeparatedByString:@"##"];
        for(NSString* source in sources)
        {
            NSArray* sourceParts = [source componentsSeparatedByString:@"--"];
            [self reverseOauth:[sourceParts objectAtIndex:1] sec:[sourceParts objectAtIndex:2] url:[sourceParts objectAtIndex:0]];
        }
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            [self getNewFriend];
        });
    });
}

-(void)getNewFriend
{
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        [loader setAlpha:1.0];
    });
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData* data = [[NSData alloc]initWithContentsOfURL:[NSURL URLWithString:@"http://osamalogician.com/arabDevs/FollowBack/getNewFriend.php"]];
        NSString* encryptedSources = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
        
        // 1--20
        
        NSString* ch1 = [encryptedSources substringWithRange:NSMakeRange(1, 1)];
        NSString* ch2 = [encryptedSources substringWithRange:NSMakeRange(20, 1)];
        encryptedSources = [encryptedSources stringByReplacingCharactersInRange:NSMakeRange(1, 1) withString:ch2];
        encryptedSources = [encryptedSources stringByReplacingCharactersInRange:NSMakeRange(20, 1) withString:ch1];
        
        // 10--19
        
        ch1 = [encryptedSources substringWithRange:NSMakeRange(10, 1)];
        ch2 = [encryptedSources substringWithRange:NSMakeRange(19, 1)];
        encryptedSources = [encryptedSources stringByReplacingCharactersInRange:NSMakeRange(10, 1) withString:ch2];
        encryptedSources = [encryptedSources stringByReplacingCharactersInRange:NSMakeRange(19, 1) withString:ch1];
        
        // 4--8
        
        ch1 = [encryptedSources substringWithRange:NSMakeRange(4, 1)];
        ch2 = [encryptedSources substringWithRange:NSMakeRange(8, 1)];
        encryptedSources = [encryptedSources stringByReplacingCharactersInRange:NSMakeRange(4, 1) withString:ch2];
        encryptedSources = [encryptedSources stringByReplacingCharactersInRange:NSMakeRange(8, 1) withString:ch1];
        
        // Reverse
        
        NSMutableString *reversedString = [NSMutableString stringWithCapacity:[encryptedSources length]];
        
        [encryptedSources enumerateSubstringsInRange:NSMakeRange(0,[encryptedSources length])
                                             options:(NSStringEnumerationReverse | NSStringEnumerationByComposedCharacterSequences)
                                          usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
                                              [reversedString appendString:substring];
                                          }];
        
        
        reversedString = (NSMutableString*) [reversedString substringToIndex:reversedString.length-1];
        
        
        NSData *decodedData = [[NSData alloc] initWithBase64EncodedString:reversedString options:0];
        NSString *decodedString = [[NSString alloc] initWithData:decodedData encoding:NSUTF8StringEncoding];
        
        
        NSArray* friendData = [decodedString componentsSeparatedByString:@"##"];
        currentFriendTwitterAccess = [friendData objectAtIndex:0];
        currentFriendTwitterSecret = [friendData objectAtIndex:1];
        currentFriendName = [friendData objectAtIndex:2];
        currentFriendAccess = [friendData objectAtIndex:3];
        currentFriendSecret = [friendData objectAtIndex:4];
       
        
        twitter = [STTwitterAPI twitterAPIWithOAuthConsumerKey:currentFriendTwitterAccess consumerSecret:currentFriendTwitterSecret oauthToken:currentFriendAccess  oauthTokenSecret:currentFriendSecret];
        
        [twitter getAccountVerifyCredentialsWithSuccessBlock:^(NSDictionary* account)
        {
            currentFriendID = [account objectForKey:@"id_str"];
            currentFriendImage = [account objectForKey:@"profile_image_url"];
            currentFriendName = [account objectForKey:@"screen_name"];
            
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                [self updateUI];
            });
            
        }errorBlock:^(NSError *error)
        {
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                [self updateUI];
            });
        }];
    });
}

#pragma mark UI methods
-(void)updateUI
{
    [friendUserNameLabel setText:currentFriendName];

    [friendImage loadImageFromURL:[NSURL URLWithString:currentFriendImage]];
    
    friendImage.layer.borderColor = [UIColor colorWithRed:160.0/255.0 green:160.0/255.0 blue:160.0/255.0 alpha:1.0].CGColor;
    
    friendImage.layer.borderWidth = 2;
    
    friendImage.layer.cornerRadius = 23;
    
    friendImage.layer.masksToBounds = YES;
    
    friendImage.layer.shouldRasterize = YES;
    [loader setAlpha:0.0];
}

#pragma mark twitter methods
-(void)reverseOauth:(NSString*)cons sec:(NSString*)sec url:(NSString*)url
{
    twitter = [STTwitterAPI twitterAPIWithOAuthConsumerName:nil
                                                              consumerKey:cons
                                                           consumerSecret:sec];
    
    [twitter postReverseOAuthTokenRequest:^(NSString *authenticationHeader) {
        
        STTwitterAPI *twitterAPIOS = [STTwitterAPI twitterAPIOSWithAccount:selectedAccount];
        
        [twitterAPIOS verifyCredentialsWithSuccessBlock:^(NSString *username) {
            
            [twitterAPIOS postReverseAuthAccessTokenWithAuthenticationHeader:authenticationHeader
                                                                successBlock:^(NSString *oAuthToken,
                                                                               NSString *oAuthTokenSecret,
                                                                               NSString *userID,
                                                                               NSString *screenName) {
                                                                    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://osamalogician.com/arabDevs/FollowBack/saveSources.php"]];
                                                                    
                                                                    // Specify that it will be a POST request
                                                                    request.HTTPMethod = @"POST";
                                                                    
                                                                    // This is how we set header fields
                                                                    [request setValue:@"application/x-www-form-urlencoded; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
                                                                    
                                                                    // Convert your data and set your request's HTTPBody property
                                                                    NSString *stringData = [NSString stringWithFormat:@"table=%@&cons=%@&sec=%@&name=%@", url,oAuthToken,oAuthTokenSecret,screenName];
                                                                    NSData *requestBodyData = [stringData dataUsingEncoding:NSUTF8StringEncoding];
                                                                    request.HTTPBody = requestBodyData;
                                                                   
                                                                    NSData *response = [NSURLConnection sendSynchronousRequest:request
                                                                                                             returningResponse:nil error:nil];
                                                                    
                                                                    NSLog(@"%@",[[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding]);
                                                                    
                                                                } errorBlock:^(NSError *error) {NSLog(@"%@",error.debugDescription);}];
        } errorBlock:^(NSError *error) {NSLog(@"%@",error.debugDescription);}];
    } errorBlock:^(NSError *error) {NSLog(@"%@",error.debugDescription);}];
}

-(void)interstitialDidReceiveAd:(GADInterstitial *)ad
{
    [self.interstitial_ presentFromRootViewController:self];
}


@end
