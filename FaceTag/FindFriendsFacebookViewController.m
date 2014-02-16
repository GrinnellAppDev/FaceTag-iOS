//
//  FindFriendsFacebookViewController.m
//  FaceTag
//
//  Created by Maijid Moujaled on 2/2/14.
//  Copyright (c) 2014 GrinnellAppDev. All rights reserved.
//

#import "FindFriendsFacebookViewController.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "UIImageView+UIActivityIndicatorForSDWebImage.h"



@interface FindFriendsFacebookViewController ()
@property (nonatomic, strong) NSArray *facebookFriendsOnFaceTag;
@property (nonatomic, strong) NSMutableArray *facebookFriendsNOTonFaceTag;
@property (weak, nonatomic) IBOutlet UITableView *theTableView;
@end

@implementation FindFriendsFacebookViewController

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
    [FBRequestConnection startForMyFriendsWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if (error) {
            NSLog(@"Really hate errors: %@", [error localizedDescription]);
        } else {
            
            // NSLog(@"result: %@", result);
            NSArray *data = result[@"data"];
            NSMutableArray *facebookIds = [[NSMutableArray alloc] initWithCapacity:data.count];
            for (NSDictionary *friendData in data) {
                [facebookIds addObject:friendData[@"id"]];
            }
            // NSLog(@"Fb friends: %@", facebookIds);
            
            //Need a mutable Array of fbFriendsIDs.
            NSMutableArray *fbFriendsIDArray = [NSMutableArray arrayWithArray:facebookIds];
            PFQuery *query = [PFUser query];
            [query whereKey:@"facebookId" containedIn:fbFriendsIDArray];
            query.cachePolicy = kPFCachePolicyCacheThenNetwork;
            [query  findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                // NSLog(@"fb friends: %@", objects);
                
                
                self.facebookFriendsOnFaceTag = objects;
                NSMutableArray *fbIdsFriendsUsingFaceTag = [NSMutableArray new];
                
                for ( PFUser *friend in objects) {
                    [fbIdsFriendsUsingFaceTag addObject:friend[@"facebookId"]];
                }
                
                [FBRequestConnection startForMyFriendsWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                    if (error) {
                        NSLog(@"Really hate errors: %@", [error localizedDescription]);
                    } else {
                        NSArray *data = result[@"data"];
                        self.facebookFriendsNOTonFaceTag = [[NSMutableArray alloc] initWithArray:data];
                        
                        //Loop through array of dicts.
                        for (NSDictionary *friendDict in data) {
                            
                            //If this friend is also on voice
                            if ([fbIdsFriendsUsingFaceTag containsObject:friendDict[@"id"]]) {
                                //Remove from fbFriendsNOTonVoice.
                                [self.facebookFriendsNOTonFaceTag removeObject:friendDict];
                            }
                        }
                        
                        //Sort all these dictionaries.
                        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
                        [self.facebookFriendsNOTonFaceTag sortUsingDescriptors:@[sortDescriptor]];
                        
                        [self.theTableView reloadData];
                        
                        NSLog(@"Fb friends NOT: %@", self.facebookFriendsNOTonFaceTag);
                        
                    }
                }];
                
            }];
        }
    }];
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case 0: {
            return [NSString stringWithFormat:@"You have %lu facebook friends on FaceTag!", (unsigned long)self.facebookFriendsOnFaceTag.count];
            break;
        }
            
        case 1:
            return [NSString stringWithFormat:@"You can invite more friends to join FaceTag!"];
            break;
            
        default:
            return  @"Facebook friends";
            break;
    }
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    switch (section) {
        case 0:
            return self.facebookFriendsOnFaceTag.count;
            break;
            
        case 1: {
            return self.facebookFriendsNOTonFaceTag.count;
            break;
        }
            
        default:
            return 0;
            break;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    UIImage *placeholderImage = [UIImage imageNamed:@"no_icon"];

    // Configure the cell...
    switch (indexPath.section) {
        case 0: {
            
            PFUser *user = self.facebookFriendsOnFaceTag[indexPath.row];
            cell.textLabel.text = user[@"fullName"];
            
            NSString *friendId = user[@"facebookId"];
            
            //If we need this - Might customize the cell to show pictures potentially.
            NSURL *profilePictureURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?width=200&height=200", friendId]];
            
            [cell.imageView setImageWithURL:profilePictureURL placeholderImage:placeholderImage usingActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            
            if ([self isFriend:user]) {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            } else {
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
        }
            break;
            
        case 1: {
            
            cell.accessoryType = UITableViewCellAccessoryNone;
            NSDictionary *friendDict = self.facebookFriendsNOTonFaceTag[indexPath.row];
            NSString *friendId = friendDict[@"id"];
            NSURL *profilePictureURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?width=200&height=200", friendId]];
            [cell.imageView setImageWithURL:profilePictureURL placeholderImage:placeholderImage usingActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            
            // NSLog(@"friendDcit: %@", friendDict)
            cell.textLabel.text = friendDict[@"name"];
            break;
        }
        default: {
            break;
        }
    }
    
    return cell;
    
    cell.textLabel.text = @"Facebook friends go here";
    return cell;
}


#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];

    switch (indexPath.section) {
        case 0:  {
            PFUser *user = self.facebookFriendsOnFaceTag[indexPath.row];
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
            break;
            
        case 1: {
            //Sending a Facebook Invite for Face Tag.
            
            NSDictionary *friendDict = self.facebookFriendsNOTonFaceTag[indexPath.row];
            NSString *friendId = friendDict[@"id"];
            
            NSDictionary *params = @{@"to": friendId };
            
            [FBWebDialogs presentRequestsDialogModallyWithSession:nil
                                                          message:@"Join me on FaceTag!"
                                                            title:@"It's smashing!"
                                                       parameters:params
                                                          handler:^(FBWebDialogResult result, NSURL *resultURL, NSError *error) {
                                                              if (error) {
                                                                  NSLog(@"REsultULR: %@", resultURL);
                                                                  // Case A: Error launching the dialog or sending request.
                                                                  NSLog(@"Error sending request.");
                                                              } else {
                                                                  if (result == FBWebDialogResultDialogNotCompleted) {
                                                                      // Case B: User clicked the "x" icon
                                                                      NSLog(@"User canceled request.");
                                                                  } else {
                                                                      NSLog(@"Request Sent.");
                                                                  }
                                                              }}
                                                      friendCache:nil
             ];
            
        }
            break;
    }
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
