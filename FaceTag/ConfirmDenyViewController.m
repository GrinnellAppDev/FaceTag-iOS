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
@property (nonatomic, weak) IBOutlet UIImageView *targetPhoto;

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
    
    // Todo - Set to the correct target name and image
    NSString *profileString = [[PFUser currentUser] objectForKey:@"profilePictureURL"];
    NSURL *profileURL = [NSURL URLWithString:profileString];
    [self.targetPhoto setImageWithURL:profileURL];
    
    self.targetConfirmationLabel.text = [[PFUser currentUser] objectForKey:@"fullName"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)confirm:(id)sender {
    // Todo - logic for this, segue only if done, else refresh with next photo
    [self performSegueWithIdentifier:@"ShowGame" sender:self];
}


- (IBAction)deny:(id)sender {
    // Todo - logic for this, segue only if done, else refresh with next photo
    [self performSegueWithIdentifier:@"ShowGame" sender:self];
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
