//
//  ConfirmDenyViewController.m
//  FaceTag
//
//  Created by Colin Tremblay on 1/18/14.
//  Copyright (c) 2014 GrinnellAppDev. All rights reserved.
//

#import "ConfirmDenyViewController.h"
#import "DeckViewController.h"
#import <SDWebImage/UIImageView+WebCache.h>

@interface ConfirmDenyViewController ()
@property (nonatomic, weak) IBOutlet UILabel *targetConfirmationLabel;
@property (nonatomic, weak) IBOutlet PFImageView *targetPhoto;
@property (nonatomic, weak) PFObject *photoTag;
@property (nonatomic, weak) PFUser *currentUser;
@property (nonatomic, assign) BOOL decided;

@end

@implementation ConfirmDenyViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.currentUser = [PFUser currentUser];
    self.photoTag = [self.unconfirmedPhotoTags firstObject];
    [self updateLabels];
}

- (void)updateLabels {
    self.decided = NO;
    self.targetPhoto.file = self.photoTag[@"photo"];
    [self.targetPhoto loadInBackground:^(UIImage *image, NSError *error) {
    }];
    self.targetConfirmationLabel.text = [NSString stringWithFormat:@"Is this %@?", self.photoTag[@"target"][@"fullName"]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)confirm:(id)sender {
    if (self.decided)
        return;
    self.decided = YES;
    if ([[self.photoTag[@"target"] objectId] isEqualToString:self.currentUser.objectId])
        [self.photoTag incrementKey:@"confirmation" byAmount:@3];
    else [self.photoTag incrementKey:@"confirmation"];

    NSMutableArray *array = self.photoTag[@"usersArray"];
    [array addObject:self.currentUser];
    [self.photoTag setObject:array forKey:@"usersArray"];
    [self.photoTag saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (!error) {
            if ([self.photoTag isEqual:[self.unconfirmedPhotoTags lastObject]])
                [self performSegueWithIdentifier:@"ShowGame" sender:self];
            else {
                self.photoTag = [self.unconfirmedPhotoTags objectAtIndex:[self.unconfirmedPhotoTags indexOfObject:self.photoTag] + 1];
                [self updateLabels];
            }
        }
    }];
}

- (IBAction)deny:(id)sender {
    if (self.decided)
        return;
    self.decided = YES;
    [self.photoTag incrementKey:@"rejection"];

    NSMutableArray *array = self.photoTag[@"usersArray"];
    [array addObject:self.currentUser];
    [self.photoTag setObject:array forKey:@"usersArray"];
    
    [self.photoTag saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (!error) {
            if ([self.photoTag isEqual:[self.unconfirmedPhotoTags lastObject]])
                [self performSegueWithIdentifier:@"ShowGame" sender:self];
            else {
                self.photoTag = [self.unconfirmedPhotoTags objectAtIndex:[self.unconfirmedPhotoTags indexOfObject:self.photoTag] + 1];
                [self updateLabels];
            }
        }
    }];
}

- (IBAction)notSure:(id)sender {
    if (self.decided)
        return;
    self.decided = YES;
    NSNumber *value = self.photoTag[@"threshold"];
    if ([value intValue] > 1)
        [self.photoTag incrementKey:@"threshold" byAmount:@-1];

    NSMutableArray *array = self.photoTag[@"usersArray"];
    [array addObject:self.currentUser];
    [self.photoTag setObject:array forKey:@"usersArray"];
    
    [self.photoTag saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (!error) {
            if ([self.photoTag isEqual:[self.unconfirmedPhotoTags lastObject]])
                [self performSegueWithIdentifier:@"ShowGame" sender:self];
            else {
                self.photoTag = [self.unconfirmedPhotoTags objectAtIndex:[self.unconfirmedPhotoTags indexOfObject:self.photoTag] + 1];
                [self updateLabels];
            }
        }
    }];
}

#pragma mark - Navigation
// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"ShowGame"]) {
        DeckViewController *deckVC = (DeckViewController *)[segue destinationViewController];
        deckVC.game = self.game;
    }
}

@end
