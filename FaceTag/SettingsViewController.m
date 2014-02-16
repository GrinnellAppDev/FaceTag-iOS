//
//  SettingsViewController.m
//  FaceTag
//
//  Created by Maijid Moujaled on 2/2/14.
//  Copyright (c) 2014 GrinnellAppDev. All rights reserved.
//

#import "SettingsViewController.h"
#import "MHTabBarController.h"
#import "FindFriendsSearchViewController.h"
#import "AllFriendsViewController.h"
#import "FindFriendsFacebookViewController.h"
#import <MessageUI/MFMailComposeViewController.h>
#import <MessageUI/MessageUI.h>
#import <StoreKit/StoreKit.h>

@interface SettingsViewController () <MHTabBarControllerDelegate, MFMailComposeViewControllerDelegate, SKStoreProductViewControllerDelegate>

@property (nonatomic, strong) NSMutableArray *friends;
@end

@implementation SettingsViewController

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.navigationController.navigationBar.translucent = NO;
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.cameraLaunchSwitch setOn:[[PFUser currentUser][@"wantsLaunchToCamera"] boolValue]];
    
    PFRelation *friendsRelation =  friendsRelation = [[PFUser currentUser] objectForKey:@"friendsRelation"];
    PFQuery *query = [friendsRelation query];
    query.cachePolicy = kPFCachePolicyCacheThenNetwork;
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (error) {
            NSLog(@"Yikes! %@", [error userInfo]);
        } else {
            self.friends = [NSMutableArray arrayWithArray:objects];
            [self.tableView reloadData];
        }
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)cameraSwitchChanged:(id)sender {
    UISwitch *switchControl = sender;
    NSNumber *switchIsOn = [NSNumber numberWithBool:switchControl.isOn];
    [[PFUser currentUser] setObject:switchIsOn forKey:@"wantsLaunchToCamera"];
    [[PFUser currentUser] saveInBackground];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0:
            if (1 == indexPath.row) {
                return; // Launch to camera is handled with switch taps, not cell taps
            }
            [self showFriendsViews];
            break;
        case 1:
            [self contactUs];
            break;
        case 2:
            [self showRateFaceTag];
            break;
        case 3:
            [self logOutCurrentUser];
            break;
        default:
            break;
    }
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)showFriendsViews {
    
    AllFriendsViewController *allFriendsVC = [self.storyboard instantiateViewControllerWithIdentifier:@"AllFriendsViewController"];
    allFriendsVC.friends = self.friends;
    allFriendsVC.title = @"Friends";
    
    FindFriendsFacebookViewController *findFriendsVC = [self.storyboard instantiateViewControllerWithIdentifier:@"FindFriendsFacebookViewController"];
    findFriendsVC.friends = self.friends;
    findFriendsVC.title = @"Facebook";
    
    FindFriendsSearchViewController *searchFriendsVC = [self.storyboard instantiateViewControllerWithIdentifier:@"FindFriendsSearchViewController"];
    searchFriendsVC.friends = self.friends;
    searchFriendsVC.title = @"Search";
    
    /*
     listViewController2.tabBarItem.image = [UIImage imageNamed:@"Taijitu"];
     listViewController2.tabBarItem.imageInsets = UIEdgeInsetsMake(0.0f, -4.0f, 0.0f, 0.0f);
     listViewController2.tabBarItem.titlePositionAdjustment = UIOffsetMake(4.0f, 0.0f);
     */
    
    NSArray *viewControllers = @[allFriendsVC, searchFriendsVC, findFriendsVC];
    MHTabBarController *tabBarController = [[MHTabBarController alloc] init];
    tabBarController.title = @"Find Friends";
    
    tabBarController.delegate = self;
    tabBarController.viewControllers = viewControllers;
    
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"navigation_arrow.png"] style:UIBarButtonItemStyleBordered target:self action:@selector(backButtonTapped:)];
    tabBarController.navigationItem.leftBarButtonItem = backButton;
    
    [self.navigationController pushViewController:tabBarController animated:YES];
}

- (void)logOutCurrentUser {
    [PFUser logOut];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)backButtonTapped:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (BOOL)mh_tabBarController:(MHTabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController atIndex:(NSUInteger)index {
	NSLog(@"mh_tabBarController %@ shouldSelectViewController %@ at index %lu", tabBarController, viewController, (unsigned long)index);
    
	// Uncomment this to prevent "Tab 3" from being selected.
	//return (index != 2);
    
	return YES;
}

- (void)mh_tabBarController:(MHTabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController atIndex:(NSUInteger)index {
	NSLog(@"mh_tabBarController %@ didSelectViewController %@ at index %lu", tabBarController, viewController, (unsigned long)index);
}

- (IBAction)close:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)contactUs {
    // From within your active view controller
    if([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController *mailViewController = [[MFMailComposeViewController alloc] init];
        mailViewController.mailComposeDelegate = self;
        
        mailViewController.navigationBar.tintColor = [UIColor colorWithRed:135.f/255.f green:1/255.f blue:6/255.f alpha:1];
        
        mailViewController.modalPresentationStyle = UIModalPresentationFormSheet;
        
        [mailViewController setSubject:@"Feedback - FaceTag!"];
        [mailViewController setToRecipients:[NSArray arrayWithObject:@"appdev@grinnell.edu"]];
        [self presentViewController:mailViewController animated:YES completion:nil];
    }
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)showRateFaceTag {
    NSDictionary *parameters = [NSDictionary dictionaryWithObject:@"803763200" forKey:SKStoreProductParameterITunesItemIdentifier];
    SKStoreProductViewController *productViewController = [[SKStoreProductViewController alloc] init];
    productViewController.delegate = self;
    [productViewController loadProductWithParameters:parameters completionBlock:nil];
    [self presentViewController:productViewController animated:YES completion:nil];
}

-(void)productViewControllerDidFinish:(SKStoreProductViewController *)viewController {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
