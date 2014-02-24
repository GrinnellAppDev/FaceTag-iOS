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
#import <SVProgressHUD.h>
#import <TDBadgedCell.h>
#import <MobileCoreServices/UTCoreTypes.h>
#import "GameCell.h"

@interface LobbyViewController () <UIAlertViewDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (nonatomic, strong) NSMutableArray *games;
@property (nonatomic, strong) NSMutableArray *userUnconfirmedPhotoTags;
@property (nonatomic, strong) GameSelectionViewController *gameSelectVC;
@property (nonatomic, assign) BOOL notFirstLaunch;
@property (nonatomic, strong) NSString *gameAlertViewTitle;
@property (nonatomic, strong) NSString *setUsernameAlertViewTitle;
@property (nonatomic, strong) NSString *pictureAlertViewTitle;
@property (nonatomic, strong) UIImagePickerController *imagePickerController;
@property (nonatomic, strong) UIImage *tagImage;

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

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
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
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (![PFUser currentUser]) {
        // We will log them in using viewDidAppear
        return;
    } else if (![PFUser currentUser][@"profilePictureURL"]) {
        self.pictureAlertViewTitle = @"You need a profile picture!";
        [[[UIAlertView alloc] initWithTitle:self.pictureAlertViewTitle message:@"You must have a profile picture so people know what you look like!" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
        return;
    }
    BOOL wantsLaunchToCamera = [[PFUser currentUser][@"wantsLaunchToCamera"] boolValue];
    
    PFQuery *participatingQuery = [PFQuery queryWithClassName:@"Game"];
    [participatingQuery whereKey:@"participants" equalTo:[[PFUser currentUser] objectId]];
    
    PFQuery *invitedQuery = [PFQuery queryWithClassName:@"Game"];
    [invitedQuery whereKey:@"invitedUsers" equalTo:[[PFUser currentUser] objectId]];
    
    PFQuery *gamesQuery = [PFQuery orQueryWithSubqueries:@[invitedQuery, participatingQuery]];
    [gamesQuery orderByAscending:@"name"];
    [gamesQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            self.games = [NSMutableArray arrayWithArray:objects];
            [self.tableView reloadData];
            __block BOOL cameraOpen = NO;
            if (!self.notFirstLaunch && wantsLaunchToCamera) {
                self.gameSelectVC = [self.storyboard instantiateViewControllerWithIdentifier:@"GameSelection"];
                self.gameSelectVC.gameArray = [[NSMutableArray alloc] init];
                self.gameSelectVC.targetDictionary = [[NSMutableDictionary alloc] init];
            }
            
            for (PFObject *game in self.games) {
                if (![game[@"participants"] containsObject:[PFUser currentUser].objectId]) {
                    [game setObject:@YES forKey:@"newGame"];
                }
                else {
                    [game setObject:@NO forKey:@"newGame"];
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
                    
                    if (!self.notFirstLaunch && wantsLaunchToCamera) {
                        NSDictionary *submittedDict = game[@"submitted"];
                        BOOL submitted = [[submittedDict objectForKey:[[PFUser currentUser] objectId]] boolValue];
                        
                        // If you have not submitted a picture for this game (in its current round)
                        //  launch the camera
                        if (!submitted) {
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
                }
            } // for
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
    /*TDBadgedCell *cell = (TDBadgedCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
     
     if (!cell) {
     cell = [[TDBadgedCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
     }
     UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
     
     PFObject *game = [self.games objectAtIndex:indexPath.row];
     cell.textLabel.text = game[@"name"];
     
     if ([[game objectForKey:@"newGame"] boolValue]) {
     cell.badgeString = @"New";
     cell.showShadow = YES;
     cell.badge.hidden = NO;
     return cell;
     }
     
     NSArray *unconfirmedPhotoTags = [[NSArray alloc] initWithArray:[game objectForKey:@"unconfirmedPhotos"]];
     if (unconfirmedPhotoTags.count > 0) {
     cell.badgeString = [NSString stringWithFormat:@"%lu", (unsigned long)unconfirmedPhotoTags.count];
     cell.showShadow = YES;
     cell.badge.hidden = NO;
     return cell;
     }
     cell.badge.hidden = YES;
     return cell;
     */
    GameCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    PFObject *game = [self.games objectAtIndex:indexPath.row];
    //cell.textLabel.text = game[@"name"];
    cell.gameNameLabel.text = game[@"name"];
    //cell.notificationLabel.text = @"N";
    cell.notificationView.backgroundColor = [UIColor faceTagBlue];
    cell.notificationView.hidden = NO;
    
    NSArray *unconfirmedPhotoTags = [[NSArray alloc] initWithArray:[game objectForKey:@"unconfirmedPhotos"]];
    
    if ([[game objectForKey:@"newGame"] boolValue]) {
        //cell.detailTextLabel.text = @"New";
        cell.notificationLabel.text = @"N";
    } else if (unconfirmedPhotoTags.count > 0) {
        //cell.detailTextLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)unconfirmedPhotoTags.count];
        cell.notificationLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)unconfirmedPhotoTags.count];
    } else {
        cell.detailTextLabel.text = @"";
        cell.notificationView.hidden = YES;
    }
    //cell.detailTextLabel.textColor = [UIColor faceTagBlue];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    PFObject *game = [self.games objectAtIndex:indexPath.row];
    if ([[game objectForKey:@"newGame"] boolValue]) {
        self.gameAlertViewTitle = @"New Game!";
        [[[UIAlertView alloc] initWithTitle:self.gameAlertViewTitle message:@"Do you want to join?" delegate:self cancelButtonTitle:@"Yes" otherButtonTitles:@"No", nil] show];
        return;
    }
    
    self.userUnconfirmedPhotoTags = [[NSMutableArray alloc] initWithArray:[game objectForKey:@"unconfirmedPhotos"]];
    if (self.userUnconfirmedPhotoTags.count > 0) {
        [self performSegueWithIdentifier:@"ConfirmDeny" sender:nil];
    } else {
        NSArray *participants = game[@"participants"];
        if (1 == participants.count) {
            [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
            [[[UIAlertView alloc] initWithTitle:@"Waiting for someone to join!" message:@"This game currently has no participants. The game will begin as soon as someone accepts your invitation!" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
            return;
        }
        [self performSegueWithIdentifier:@"ShowGame" sender:nil];
    }
}

#pragma mark - Alert View delegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([alertView.title isEqualToString:self.gameAlertViewTitle]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        
        PFObject *game = [self.games objectAtIndex:indexPath.row];
        NSMutableArray *invitedUsers = game[@"invitedUsers"];
        [invitedUsers removeObject:[PFUser currentUser].objectId];
        game[@"invitedUsers"] = invitedUsers;
        
        if (0 == buttonIndex) {
            NSMutableArray *participants = game[@"participants"];
            [participants addObject:[PFUser currentUser].objectId];
            game[@"participants"] = participants;
            [game setObject:@NO forKey:@"newGame"];
            [game saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (!error) {
                    [self performSegueWithIdentifier:@"ShowGame" sender:self];
                }
            }];
        } else {
            [game saveInBackground];
            [self.games removeObject:game];
            [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
            [self.tableView reloadData];
        }
    } else if ([alertView.title isEqualToString:self.setUsernameAlertViewTitle]) {
        if (0 == buttonIndex) {
            PFUser *currentUser = [PFUser currentUser];
            currentUser[@"username"] = [alertView textFieldAtIndex:0].text;
            [currentUser saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (error) {
                    [SVProgressHUD showErrorWithStatus:@"An error occured. Your username must be unique. Try again!"];
                    NSLog(@"%@", error.localizedDescription);
                } else {
                    [self dismissViewControllerAnimated:YES completion:^{
                        [self dismissViewControllerAnimated:YES completion:nil];
                    }];
                }
            }];
        } else {
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    } else if ([alertView.title isEqualToString:self.pictureAlertViewTitle]) {
        [self showPhotoPicker];
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
                            self.setUsernameAlertViewTitle = @"Do you want to set your username?";
                            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:self.setUsernameAlertViewTitle message:@"You can set a username to separate the login process from facebook!" delegate:self cancelButtonTitle:@"Update" otherButtonTitles:@"Cancel", nil];
                            alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
                            [alertView show];
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

- (void)uploadProfilePhoto {
    NSData *imageData = UIImagePNGRepresentation(self.tagImage);
    PFUser *currentUser = [PFUser currentUser];
    NSString *fileName =  [NSString stringWithFormat:@"%@-ProfileImage", currentUser[@"firstName"]];
    PFFile *imageFile = [PFFile fileWithName:fileName data:imageData];
    
    [imageFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (!error) {
            currentUser[@"profilePictureURL"] = imageFile.url;
            [currentUser saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                [SVProgressHUD dismiss];
                [self dismissViewControllerAnimated:YES completion:nil];
            }];
        }
    }];
}

#pragma mark - UIImagePickerDelegate Stuff.
- (void)showPhotoPicker {
    if (!self.imagePickerController) {
        self.imagePickerController = [[UIImagePickerController alloc] init];
        self.imagePickerController.delegate = self;
        self.imagePickerController.allowsEditing = NO;
    }
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        self.imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
        self.imagePickerController.mediaTypes = @[(NSString *)kUTTypeImage];
        
        [self presentViewController:self.imagePickerController animated:NO completion:nil];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error accessing media" message:@"Device doesn't support that media source."  delegate:nil
                                              cancelButtonTitle:@"Drat!"
                                              otherButtonTitles:nil];
        [alert show];
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    NSString *mediaType = info[UIImagePickerControllerMediaType];
    if ([mediaType isEqualToString:(NSString *)kUTTypeImage]) {
        [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeGradient];
        
        UIImage *image = info[UIImagePickerControllerOriginalImage];
        
        //Get the ratio and scale the height according to that ratio.
        int ratio = image.size.width / 320.0;
        int newHeight = image.size.height / ratio;
        self.tagImage =  [self resizeImage:image toWidth:320 andHeight:newHeight];
        
        [self uploadProfilePhoto];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (UIImage *)resizeImage:(UIImage *)image toWidth:(float)width andHeight:(float)height {
    CGSize newSize = CGSizeMake(width, height);
    CGRect newRectangle = CGRectMake(0, 0, width, height);
    
    UIGraphicsBeginImageContext(newSize);
    [image drawInRect:newRectangle];
    UIImage *resizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return resizedImage;
}

@end
