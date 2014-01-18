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
    self.photoTag = [self.unconfirmedPhotoTags firstObject];
    self.targetPhoto.file = self.photoTag[@"photo"];
    [self.targetPhoto loadInBackground:^(UIImage *image, NSError *error) {
    }];
    self.targetConfirmationLabel.text = [NSString stringWithFormat:@"Is this %@?", self.photoTag[@"target"]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)confirm:(id)sender {
    NSNumber *value = self.photoTag[@"confirmation"];
    int confInt = [value intValue];
    [self.photoTag setObject:@(++confInt) forKey:@"confirmation"];
    NSMutableArray *array = self.photoTag[@"usersArray"];
    [array addObject:[PFUser currentUser]];
    [self.photoTag setObject:array forKey:@"usersArray"];
    [self.photoTag saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (!error) {
            // Todo - Segue only if done, else refresh with next photo
            [self performSegueWithIdentifier:@"ShowGame" sender:self];
        }
    }];
}


- (IBAction)deny:(id)sender {
    NSNumber *value = self.photoTag[@"rejection"];
    int rejInt = [value intValue];
    [self.photoTag setObject:@(++rejInt) forKey:@"rejection"];
    NSMutableArray *array = self.photoTag[@"usersArray"];
    [array addObject:[PFUser currentUser]];
    [self.photoTag setObject:array forKey:@"usersArray"];
    
    [self.photoTag saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (!error) {
            // Todo - Segue only if done, else refresh with next photo
            [self performSegueWithIdentifier:@"ShowGame" sender:self];
        }
    }];}

#pragma mark - Navigation
// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"ShowGame"]) {
        DeckViewController *deckVC = (DeckViewController *)[segue destinationViewController];
        deckVC.game = self.game;
    }
}

@end
