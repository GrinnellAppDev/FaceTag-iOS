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

@interface LobbyViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (nonatomic, strong) UIImagePickerController *imagePickerController;
@property (nonatomic, strong) UIImage *tagImage;
@property (nonatomic, strong) NSArray *games;
@property (nonatomic, strong) NSMutableArray *userUnconfirmedPhotoTags;

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
                
                PFQuery *roundQuery = [PFQuery queryWithClassName:@"PhotoTag"];
                [roundQuery whereKey:@"sender" equalTo:[PFUser currentUser]];
                [roundQuery whereKey:@"game" equalTo:game.objectId];
                [roundQuery whereKey:@"round" equalTo:game[@"round"]];
                [roundQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                    if (!error) {
                        // If you have no submitted picture for any game (in its current round)
                        //  launch the camera
                        if (!objects.count) {
                            NSLog(@"launch camera");
                        }
                    }
                }];
            }
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

@end
