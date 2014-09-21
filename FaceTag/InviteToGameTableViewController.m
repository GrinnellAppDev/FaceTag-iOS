//
//  InviteToGameTableViewController.m
//  FaceTag
//
//  Created by Maijid Moujaled on 1/18/14.
//  Copyright (c) 2014 GrinnellAppDev. All rights reserved.
//

#import "InviteToGameTableViewController.h"
#import "SetupViewController.h"
#import "UserCell.h"
#import "UIImageView+UIActivityIndicatorForSDWebImage.h"


@interface InviteToGameTableViewController ()

@property (nonatomic, strong) NSArray *allUsers;
@property (nonatomic, strong) NSMutableArray *usersToInvite;
@property (nonatomic, strong) SetupViewController *setupViewController;

@end

@implementation InviteToGameTableViewController

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.setupViewController = (SetupViewController *)self.parentViewController.childViewControllers.firstObject;
    
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"navigation_arrow.png"] style:UIBarButtonItemStyleBordered target:self action:@selector(backButtonTapped:)];
    self.navigationItem.leftBarButtonItem = backButton;
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    //Set the background of the TableView
    UIImageView *backgroundImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"game_background_light"]];
    [backgroundImageView setFrame:self.tableView.frame];
    self.tableView.backgroundView = backgroundImageView;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[UIBarButtonItem appearance] setBackButtonTitlePositionAdjustment:UIOffsetMake(0, -80.0f) forBarMetrics:UIBarMetricsDefault];
    
    self.friendsRelation = [[PFUser currentUser] objectForKey:@"friendsRelation"];
    PFQuery *query = [self.friendsRelation query];
    query.cachePolicy = kPFCachePolicyCacheThenNetwork;
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (error) {
            NSLog(@"Yikes! %@", [error userInfo]);
        } else {
            self.friends = objects;
            [self.tableView reloadData];
        }
    }];
    
    
    /*
    PFQuery *userQuery  = [PFUser query];
    
    //Exclude the current logged in user
    [userQuery whereKey:@"objectId" notEqualTo:[PFUser currentUser].objectId];
    [userQuery orderByAscending:@"fullName"];
    
    [userQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            self.allUsers = objects;
            [self.tableView reloadData];
        }
    }];
     */
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)backButtonTapped:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return self.friends.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"UserCell";
    UserCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    PFUser *user = self.friends[indexPath.row];
    
    // Configure the cell...
    if ([self.setupViewController.usersToInvite containsObject:user.objectId]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    NSURL *profilePictureURL = user[@"profilePictureURL"];
    [cell.profilePictureImageView sd_setImageWithURL:profilePictureURL placeholderImage:nil];
    
    cell.nameLabel.text = user[@"fullName"];
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    //Add or remove this user from the
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    PFUser *user = [self.friends objectAtIndex:indexPath.row];
    
    if (cell.accessoryType == UITableViewCellAccessoryNone) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        
        [self.setupViewController.usersToInvite addObject:user.objectId];
    }
    else {
        cell.accessoryType = UITableViewCellAccessoryNone;
        [self.setupViewController.usersToInvite removeObject:user.objectId];
    }
}

- (IBAction)doneButtonTapped:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}
@end
