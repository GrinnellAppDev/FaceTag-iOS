//
//  GameViewController.m
//  FaceTag
//
//  Created by Colin Tremblay on 1/17/14.
//  Copyright (c) 2014 GrinnellAppDev. All rights reserved.
//

#import "GameViewController.h"
#import <QuartzCore/QuartzCore.h>
#import <SDWebImage/UIImageView+WebCache.h>

@interface GameViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *targetProfileImageView;
@property (weak, nonatomic) IBOutlet UILabel *targetNameLabel;
@end

@implementation GameViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    
    self.targetProfileImageView.layer.cornerRadius = 40;
    self.targetProfileImageView.layer.masksToBounds = YES;
    
    // TODO (DrJid): Set the target user correctly!
    NSString *profileString = [[PFUser currentUser] objectForKey:@"profilePictureURL"];
    NSURL *profileURL = [NSURL URLWithString:profileString];
    [self.targetProfileImageView setImageWithURL:profileURL];
    
    self.targetNameLabel.text = [[PFUser currentUser] objectForKey:@"fullName"]; 

    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)showCamera:(id)sender {
    
    [self performSegueWithIdentifier:@"ShowCamera" sender:self];
}

@end
