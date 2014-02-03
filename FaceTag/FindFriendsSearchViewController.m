//
//  FindFriendsSearchViewController.m
//  FaceTag
//
//  Created by Maijid Moujaled on 2/2/14.
//  Copyright (c) 2014 GrinnellAppDev. All rights reserved.
//

#import "FindFriendsSearchViewController.h"

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

    
    PFQuery *fullNameQuery = [PFUser query];
    [fullNameQuery whereKey:@"fullName" containsString:searchTerm];
    [fullNameQuery whereKey:@"objectId" notEqualTo:[PFUser currentUser].objectId];
    
    [fullNameQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        self.usersArray = [NSMutableArray arrayWithArray: objects];
        NSLog(@"objects: %@", objects);
        [self.theTableView reloadData];
        self.theTableView.hidden = NO;
    }];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
        return self.usersArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    PFUser *user = self.usersArray[indexPath.row];

    static NSString *cellIdentifier = @"UserCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if ([self isFriend:user]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;

    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }

    cell.textLabel.text = user[@"fullName"];
    return cell;
}


#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES]; 
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    PFUser *user = self.usersArray[indexPath.row];
    NSLog(@"Selected user: %@", user);
    
    
   PFRelation *friendsRelation = [[PFUser currentUser] relationforKey:@"friendsRelation"];
    
    if ([self isFriend:user]) {
        
        cell.accessoryType = UITableViewCellAccessoryNone;
        
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
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
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
