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
#import "FindFriendsContactViewController.h"
#import "FindFriendsFacebookViewController.h"

@interface SettingsViewController () <MHTabBarControllerDelegate>

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
    if (1 == indexPath.row) {
        return;
    }
    
    FindFriendsSearchViewController *ffSVC = [self.storyboard instantiateViewControllerWithIdentifier:@"FindFriendsSearchViewController"];
    ffSVC.friends = self.friends;
    ffSVC.title = @"Search";
    
    FindFriendsFacebookViewController *ffFVC = [self.storyboard instantiateViewControllerWithIdentifier:@"FindFriendsFacebookViewController"];
    ffFVC.friends = self.friends; 
    ffFVC.title = @"Facebook";
    
    FindFriendsContactViewController *ffCVC = [self.storyboard instantiateViewControllerWithIdentifier:@"FindFriendsContactViewController"];
    ffCVC.title = @"Contact";

    /*
     listViewController2.tabBarItem.image = [UIImage imageNamed:@"Taijitu"];
     listViewController2.tabBarItem.imageInsets = UIEdgeInsetsMake(0.0f, -4.0f, 0.0f, 0.0f);
     listViewController2.tabBarItem.titlePositionAdjustment = UIOffsetMake(4.0f, 0.0f);
     */
    
	NSArray *viewControllers = @[ffSVC, ffFVC, ffCVC];
	MHTabBarController *tabBarController = [[MHTabBarController alloc] init];
    
	tabBarController.delegate = self;
	tabBarController.viewControllers = viewControllers;
    
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"navigation_arrow.png"] style:UIBarButtonItemStyleBordered target:self action:@selector(backButtonTapped:)];
    tabBarController.navigationItem.leftBarButtonItem = backButton;
    
    
    [self.navigationController pushViewController:tabBarController animated:YES];
}

- (void)backButtonTapped:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (BOOL)mh_tabBarController:(MHTabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController atIndex:(NSUInteger)index {
	NSLog(@"mh_tabBarController %@ shouldSelectViewController %@ at index %u", tabBarController, viewController, index);
    
	// Uncomment this to prevent "Tab 3" from being selected.
	//return (index != 2);
    
	return YES;
}

- (void)mh_tabBarController:(MHTabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController atIndex:(NSUInteger)index {
	NSLog(@"mh_tabBarController %@ didSelectViewController %@ at index %u", tabBarController, viewController, index);
}


#pragma mark - Table view data source

/*
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
#warning Potentially incomplete method implementation.
    // Return the number of sections.
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
#warning Incomplete method implementation.
    // Return the number of rows in the section.
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
 
    // Configure the cell...
    
    return cell;
}

*/

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

 */
- (IBAction)close:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
