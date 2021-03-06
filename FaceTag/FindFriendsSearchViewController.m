//
//  FindFriendsSearchViewController.m
//  FaceTag
//
//  Created by Maijid Moujaled on 2/2/14.
//  Copyright (c) 2014 GrinnellAppDev. All rights reserved.
//

#import "FindFriendsSearchViewController.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "UserCell.h"

@interface FindFriendsSearchViewController ()
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UITableView *theTableView;
@property (nonatomic, strong) NSMutableArray *usersArray;
@end

@implementation FindFriendsSearchViewController

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

- (void)viewWillAppear:(BOOL)animated
{
    [self performSelector:@selector(showKeyboard) withObject:nil afterDelay:0.1f];
}

- (void)showKeyboard
{
    [self.searchBar becomeFirstResponder];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [self performSearch:self.searchBar.text];
}

- (void)performSearch:(NSString *)searchTerm
{
    PFQuery *firstNameQuery = [PFUser query];
    [firstNameQuery whereKey:@"firstName" containsString:searchTerm];
    [firstNameQuery whereKey:@"objectId" notEqualTo:[PFUser currentUser].objectId];
    
    PFQuery *lastNameQuery = [PFUser query];
    [lastNameQuery whereKey:@"lastName" containsString:searchTerm];
    [lastNameQuery whereKey:@"objectId" notEqualTo:[PFUser currentUser].objectId];
    
    PFQuery *query = [PFQuery orQueryWithSubqueries:@[firstNameQuery, lastNameQuery]];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        self.usersArray = [NSMutableArray arrayWithArray:objects];
        [self.theTableView reloadData];
        self.theTableView.hidden = NO;
    }];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.usersArray == nil) {
        return 0;
    } else if (self.usersArray.count == 0) {
        return 1;
    } else {
        return self.usersArray.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

  
    NSLog(@"self.usersArra: %lu", (unsigned long)self.usersArray.count);
    if (self.usersArray.count == 0) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"NoUserFoundCell"];
        return cell;
    }
    
    UserCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UserCell"];
    PFUser *user = self.usersArray[indexPath.row];
    UIImage *placeholderImage = [UIImage imageNamed:@"no_icon"];

    [cell.addFriendButton addTarget:self action:@selector(addFriendButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    
    if ([self isFriend:user]) {
        [cell.addFriendButton setImage:[UIImage imageNamed:@"facetag_checkmark"] forState:UIControlStateNormal];
    } else {
        [cell.addFriendButton setImage:[UIImage imageNamed:@"facetag_plus"] forState:UIControlStateNormal];
    }

    cell.nameLabel.text = user[@"fullName"];
    
    NSURL *profilePictureURL = user[@"profilePictureURL"];
    [cell.profilePictureImageView sd_setImageWithURL:profilePictureURL placeholderImage:placeholderImage];
    
    return cell;
}

- (void)addFriendButtonPressed:(id)sender
{
    UserCell *cell = (UserCell *)[[[sender superview] superview] superview];
    NSIndexPath *indexPath = [self.theTableView indexPathForCell:cell];
    
    PFRelation *friendsRelation = [[PFUser currentUser] relationForKey:@"friendsRelation"];
    
    PFUser *user = self.usersArray[indexPath.row];
    
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
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/


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
