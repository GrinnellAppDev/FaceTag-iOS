//
//  LobbyViewController.m
//  FaceTag
//
//  Created by Colin Tremblay on 1/17/14.
//  Copyright (c) 2014 GrinnellAppDev. All rights reserved.
//

#import "LobbyViewController.h"
#import "DeckViewController.h"
#import "ConfirmDenyViewController.h"
#import "GameSelectionViewController.h"
#import <TDBadgedCell.h>

@interface LobbyViewController ()

@property (nonatomic, strong) NSArray *games;
@property (nonatomic, strong) NSMutableArray *userUnconfirmedPhotoTags;
@property (nonatomic, strong) GameSelectionViewController *gameSelectVC;
@property (nonatomic, assign) BOOL notFirstLaunch;

@end

@implementation LobbyViewController

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
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    
    if (![PFUser currentUser]) {
        PFLogInViewController *loginVC = [[PFLogInViewController alloc] init];
        [loginVC setDelegate:self];
        loginVC.fields = PFLogInFieldsUsernameAndPassword | PFLogInFieldsPasswordForgotten | PFLogInFieldsLogInButton | PFLogInFieldsFacebook | PFLogInFieldsSignUpButton;
        loginVC.facebookPermissions = @[@"email"];;
        [loginVC.logInView.externalLogInLabel setText:@"You can also log in or sign up with"];
        loginVC.logInView.logo = nil;
        
        PFSignUpViewController *signUpVC = [[PFSignUpViewController alloc] init];
        signUpVC.fields = PFSignUpFieldsUsernameAndPassword | PFSignUpFieldsEmail | PFSignUpFieldsDismissButton | PFSignUpFieldsSignUpButton | PFSignUpFieldsAdditional;
        [signUpVC.signUpView.additionalField setPlaceholder:@"Full Name"];
        [signUpVC setDelegate:self];
        signUpVC.signUpView.logo = nil;
        loginVC.signUpController = signUpVC;
        
        [self presentViewController:loginVC animated:YES completion:nil];
        return;
    }
    
    PFQuery *gamesQuery  = [PFQuery queryWithClassName:@"Game"];
    [gamesQuery whereKey:@"participants" equalTo:[[PFUser currentUser] objectId]];
    [gamesQuery orderByAscending:@"name"];
    [gamesQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            self.games = objects;
            [self.tableView reloadData];
            __block BOOL cameraOpen = NO;
            if (!self.notFirstLaunch) {
                self.gameSelectVC = [self.storyboard instantiateViewControllerWithIdentifier:@"GameSelection"];
                self.gameSelectVC.gameArray = [[NSMutableArray alloc] init];
                self.gameSelectVC.targetDictionary = [[NSMutableDictionary alloc] init];
            }
            
            for (PFObject *game in self.games) {
                PFQuery *picQuery = [PFQuery queryWithClassName:@"PhotoTag"];
                [picQuery whereKey:@"game" equalTo:game.objectId];
                [picQuery whereKey:@"usersArray" notEqualTo:[PFUser currentUser]];
                [picQuery includeKey:@"target"];
                [picQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                    if (!error) {
                        [game setObject:objects forKey:@"unconfirmedPhotos"];
                        [self.tableView reloadData];
                    }
                }];
                
                if (!self.notFirstLaunch) {
                    PFQuery *roundQuery = [PFQuery queryWithClassName:@"PhotoTag"];
                    [roundQuery whereKey:@"sender" equalTo:[PFUser currentUser]];
                    [roundQuery whereKey:@"game" equalTo:game.objectId];
                    [roundQuery whereKey:@"round" equalTo:game[@"round"]];
                    [roundQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                        if (!error) {
                            // If you have no submitted picture for any game (in its current round)
                            //  launch the camera
                            if (!objects.count) {
                                if (!cameraOpen) {
                                    cameraOpen = YES;
                                    [self launchToCamera];
                                }
                                [self.gameSelectVC.gameArray addObject:game];
                                NSDictionary *pairings = game[@"pairings"];
                                NSString *targetUserId = [pairings objectForKey:[[PFUser currentUser] objectId]];
                                PFQuery *targetUserQuery = [PFUser query];
                                [targetUserQuery getObjectInBackgroundWithId:targetUserId block:^(PFObject *object, NSError *error) {
                                    if (!error) {
                                        [self.gameSelectVC.targetDictionary setValue:object forKey:game[@"name"]];
                                        [self.gameSelectVC.tableView reloadData];
                                    }
                                }];
                            }
                        }
                    }];
                }
            }
            self.notFirstLaunch = YES;
        }
    }];
}

- (void)launchToCamera {
    UINavigationController *navC = [[UINavigationController alloc] initWithRootViewController:self.gameSelectVC];
    [self presentViewController:navC animated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return self.games.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"GameCell";
    TDBadgedCell *cell = (TDBadgedCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    if (!cell) {
        cell = [[TDBadgedCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }

    PFObject *game = [self.games objectAtIndex:indexPath.row];
    NSArray *unconfirmedPhotoTags = [[NSArray alloc] initWithArray:[game objectForKey:@"unconfirmedPhotos"]];

    if (unconfirmedPhotoTags.count > 0) {
        cell.badgeString = [NSString stringWithFormat:@"%lu", (unsigned long)unconfirmedPhotoTags.count];
        cell.showShadow = YES;
    }
    
    cell.textLabel.text = game[@"name"];
    
    return cell;
}
- (BOOL)currentUserIsPresent:(PFObject *)photoTag {
    for (PFUser *user in photoTag[@"usersArray"]) {
        if ([user.objectId isEqualToString:[PFUser currentUser].objectId]) {
            return YES;
        }
    }
    return NO;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    PFObject *game = [self.games objectAtIndex:indexPath.row];
    self.userUnconfirmedPhotoTags = [[NSMutableArray alloc] initWithArray:[game objectForKey:@"unconfirmedPhotos"]];
    if (self.userUnconfirmedPhotoTags.count > 0) {
        [self performSegueWithIdentifier:@"ConfirmDeny" sender:nil];
    } else {
        [self performSegueWithIdentifier:@"ShowGame" sender:nil];
    }
}

#pragma mark - Navigation
// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"ShowGame"]) {
        DeckViewController *deckVC = (DeckViewController *)[segue destinationViewController];
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        deckVC.game = [self.games objectAtIndex:indexPath.row];
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
    else if ([segue.identifier isEqualToString:@"ConfirmDeny"]) {
        ConfirmDenyViewController *confirmDenyVC = (ConfirmDenyViewController *)[segue destinationViewController];
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        confirmDenyVC.game = [self.games objectAtIndex:indexPath.row];
        confirmDenyVC.unconfirmedPhotoTags = [[NSArray alloc] initWithArray:self.userUnconfirmedPhotoTags];
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

#pragma mark PFLogInVC & PFSignUpVC
- (BOOL)logInViewController:(PFLogInViewController *)logInController shouldBeginLogInWithUsername:(NSString *)username password:(NSString *)password {
    if (username && password && 0 != username.length && 0 != password.length) {
        return YES;
    }

    [[[UIAlertView alloc] initWithTitle:@"Missing Information" message:@"Make sure you fill out all of the information" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
    return NO;
}

- (void)logInViewController:(PFLogInViewController *)logInController didLogInUser:(PFUser *)user {
    [FBRequestConnection startForMeWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if (error) {
           // NSLog(@"Something went wrong requesting facebook details: %@", [error localizedDescription]);
            [self dismissViewControllerAnimated:YES completion:nil];
        }  else {
            NSDictionary<FBGraphUser> *me = (NSDictionary<FBGraphUser> *)result;
            //NSLog(@"me: %@",me);
            
            PFUser *currentUser = [PFUser currentUser];
            currentUser[@"facebookId"] = me.id;
            currentUser[@"fullName"] = me.name;
            currentUser[@"firstName"] = me.first_name;
            currentUser[@"lastName"] = me.last_name;
            
            //If facebook user permitted us to having email.
            if(me[@"email"]) {
                //only update the email if there is none.
                if (!currentUser[@"email"]) {
                    currentUser[@"email"] = me[@"email"];
                }
            }
            
            NSString *profilePictureURL = [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?width=200&height=200", me.id];
            
            //Update the profile picture with a facebook one.
            currentUser[@"profilePictureURL"] = profilePictureURL;
            
            [currentUser saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (error) {
                    //NSLog(@"I hate errors: %@", [error localizedDescription]);
                } else {
                    //NSLog(@"No error, user should've saved");
                    PFInstallation *installation = [PFInstallation currentInstallation];
                    installation[@"owner"] = [PFUser currentUser];
                    [installation saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                        if (succeeded) {
                            //NSLog(@"Installation saved");
                            [self dismissViewControllerAnimated:YES completion:nil];
                        }
                    }];
                }
            }];
        }
    }];
}

- (void)signUpViewController:(PFSignUpViewController *)signUpController didSignUpUser:(PFUser *)user {
    NSString *fullName = signUpController.signUpView.additionalField.text;
    NSRange index = [fullName rangeOfString:@" "];
    NSString *firstName = [fullName substringToIndex:index.location];
    NSString *lastName = [fullName substringFromIndex:index.location + 1];
    
    [user setValue:fullName forKey:@"fullName"];
    [user setValue:firstName forKey:@"firstName"];
    [user setValue:lastName forKey:@"lastName"];

    [user save];
    
    PFInstallation *installation = [PFInstallation currentInstallation];
    installation[@"owner"] = [PFUser currentUser];
    [installation saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            //NSLog(@"Installation saved");
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }];
}

- (BOOL)signUpViewController:(PFSignUpViewController *)signUpController shouldBeginSignUp:(NSDictionary *)info {
    if (info[@"username"] && info[@"password"] && info[@"email"] && info[@"additional"]) {
        if (NSNotFound == [info[@"additional"] rangeOfString:@" "].location) {
            [[[UIAlertView alloc] initWithTitle:@"Missing Information" message:@"Your full name must include a first and last name, separated by a space." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
            return NO;
        }
        return YES;
    }
    
    [[[UIAlertView alloc] initWithTitle:@"Missing Information" message:@"Make sure you fill out all of the information" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
    return NO;
}

@end