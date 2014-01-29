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
#import <MobileCoreServices/UTCoreTypes.h>
#import "GameSelectionViewController.h"

@interface LobbyViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (nonatomic, strong) UIImagePickerController *imagePickerController;
@property (nonatomic, strong) UIImage *tagImage;
@property (nonatomic, strong) NSArray *games;
@property (nonatomic, strong) NSMutableArray *userUnconfirmedPhotoTags;
@property (nonatomic, strong) NSMutableArray *modalArray;
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
                                [self.gameSelectVC.gameArray addObject:game];
                                NSDictionary *pairings = game[@"pairings"];
                                NSString *targetUserId = [pairings objectForKey:[[PFUser currentUser] objectId]];
                                PFQuery *targetUserQuery = [PFUser query];
                                [targetUserQuery getObjectInBackgroundWithId:targetUserId block:^(PFObject *object, NSError *error) {
                                    if (!error) {
                                        [self.gameSelectVC.targetDictionary setValue:object forKey:game[@"name"]];
                                    }
                                }];

                                if (!cameraOpen) {
                                    cameraOpen = YES;
                                    [self showTagPhotoPicker];
                                }
                            }
                        }
                    }];
                }
            }
            self.notFirstLaunch = YES;
        }
    }];
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
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    cell.textLabel.text = [self.games objectAtIndex:indexPath.row][@"name"];
    // Configure the cell...
    
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

#pragma mark - UIImagePickerDelegate Stuff.
- (void)showTagPhotoPicker {
    // Create image picker
    if (!self.imagePickerController) {
        self.imagePickerController = [[UIImagePickerController alloc] init];
        self.imagePickerController.delegate = self;
        self.imagePickerController.allowsEditing = NO;
    }
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        self.imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
        self.imagePickerController.mediaTypes = @[(NSString *)kUTTypeImage];
        
        //Create overlay view.
        UIView *overlayView = [[UIView alloc] initWithFrame:self.imagePickerController.view.frame];
        UIImageView *imgView = [[UIImageView alloc] initWithFrame:overlayView.frame];
        imgView.image = [UIImage imageNamed:@"camera"];
        imgView.alpha = 0.4;
        imgView.contentMode = UIViewContentModeCenter;
        
        //Without these.. the buttons get disabled.
        [overlayView setUserInteractionEnabled:NO];
        [overlayView setExclusiveTouch:NO];
        [overlayView setMultipleTouchEnabled:NO];
        [overlayView addSubview:imgView];
        
        self.imagePickerController.cameraOverlayView = overlayView;
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
        UIImage *image = info[UIImagePickerControllerOriginalImage];
        
        //Get the ratio and scale the height according to that ratio.
        int ratio = image.size.width / 320.0;
        int newHeight = image.size.height / ratio;
        self.gameSelectVC.tagImage =  [self resizeImage:image toWidth:320 andHeight:newHeight];
        [self dismissViewControllerAnimated:YES completion:^{
            UINavigationController *navC = [[UINavigationController alloc] initWithRootViewController:self.gameSelectVC];
            [self presentViewController:navC animated:YES completion:nil];
        }];
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
