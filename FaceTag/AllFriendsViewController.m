//
//  FindFriendsContactViewController.m
//  FaceTag
//
//  Created by Maijid Moujaled on 2/2/14.
//  Copyright (c) 2014 GrinnellAppDev. All rights reserved.
//

#import "AllFriendsViewController.h"
#import "UserCell.h"
#import "UIImageView+UIActivityIndicatorForSDWebImage.h"


@interface AllFriendsViewController ()
@property (weak, nonatomic) IBOutlet UITableView *theTableView;

@property (nonatomic, strong) NSMutableArray *allFriends;

@end

@implementation AllFriendsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    //Get all the users current friends.
    NSLog(@"View will appear");
    
    PFRelation *friendsRelation = [[PFUser currentUser] relationforKey:@"friendsRelation"];
    
    PFQuery *query = [friendsRelation query];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (error) {
            NSLog(@"Error %@ %@", error, [error userInfo]);
        }
        else {
            
            self.allFriends = [NSMutableArray arrayWithArray: objects];
            NSLog(@"self.friends: %@", self.allFriends);
            [self.theTableView reloadData];
        }
    }];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return self.allFriends.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"UserCell";
    UserCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    PFUser *user = self.allFriends[indexPath.row];
    
    UIImage *placeholderImage = [UIImage imageNamed:@"no_icon_light"];
    
     [cell.addFriendButton addTarget:self action:@selector(addFriendButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    
    if ([self isFriend:user]) {
        [cell.addFriendButton setImage:[UIImage imageNamed:@"facetag_checkmark"] forState:UIControlStateNormal];
    } else {
        [cell.addFriendButton setImage:[UIImage imageNamed:@"facetag_plus"] forState:UIControlStateNormal];
    }
    
    
    /*
    if ([self.recipients containsObject:user.objectId]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    [cell.userImageView setImageWithURL:user[@"profilePictureURL"] placeholderImage:placeholderImage];
    cell.nameLabel.text = user.username;
    */
    
    NSURL *profilePictureURL = user[@"profilePictureURL"];
    [cell.profilePictureImageView setImageWithURL:profilePictureURL placeholderImage:placeholderImage];
    
    cell.nameLabel.text = user[@"firstName"];
    return cell;
}

- (void)addFriendButtonPressed:(id)sender
{
    UserCell *cell = (UserCell *)[[[sender superview] superview] superview];
    NSIndexPath *indexPath = [self.theTableView indexPathForCell:cell];
    
    PFRelation *friendsRelation = [[PFUser currentUser] relationforKey:@"friendsRelation"];
    PFUser *user = self.allFriends[indexPath.row];
    
    
    
    if ([self isFriend:user]) {
        
        [cell.addFriendButton setImage:[UIImage imageNamed:@"facetag_plus"] forState:UIControlStateNormal];
        
        for (PFUser *friend in self.friends) {
            if ([friend.objectId isEqualToString:user.objectId]) {
                [self.friends removeObject:friend];
                break;
            }
        }
        
        NSLog(@"Removing friend: %@", user[@"firstName"]);
        [friendsRelation removeObject:user];
        
    } else {
        NSLog(@"Will add friend: %@", user.username);
        [friendsRelation addObject:user];
        [cell.addFriendButton setImage:[UIImage imageNamed:@"facetag_checkmark"] forState:UIControlStateNormal];
        [self.friends addObject:user];
    }
    
    [[PFUser currentUser] saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (error) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Unable to complete adding friend.." message:nil delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil];
            [alert show];
        } else {
            NSLog(@"Helll yeah!!!");
        }
    }];
}


#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

}


#pragma mark - Helper Methods.

- (BOOL)isFriend:(PFUser *)user {
    for(PFUser *friend in self.friends) {
        if ([friend.objectId isEqualToString:user.objectId]) {
            return YES;
        }
    }
    return NO;
}

@end
