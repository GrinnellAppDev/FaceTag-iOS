//
//  LoginViewController.m
//  FaceTag
//
//  Created by Colin Tremblay on 1/17/14.
//  Copyright (c) 2014 GrinnellAppDev. All rights reserved.
//

#import "LoginViewController.h"

@interface LoginViewController ()

@end

@implementation LoginViewController

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

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    //If there is a current user, set the lobby View Controller as the initial View Controller.
    if ([PFUser currentUser]) {

        [self performSegueWithIdentifier:@"Login" sender:self];
    }
}

- (IBAction)loginButtonTouchHandler:(id)sender {
    // The permissions requested from the user
    NSArray *permissionsArray = @[ @"email" ];
    
    // Login PFUser using Facebook
    [PFFacebookUtils logInWithPermissions:permissionsArray block:^(PFUser *user, NSError *error) {
        //[_activityIndicator stopAnimating]; // Hide loading indicator
        
        if (!user) {
            if (!error) {
                NSLog(@"Uh oh. The user cancelled the Facebook login.");
            } else {
                NSLog(@"Uh oh. An error occurred: %@", error);
            }
        } else if (user.isNew) {
            NSLog(@"User with facebook signed up and logged in!");
            //[self performSegueWithIdentifier:@"Login" sender:sender];
        } else {
            NSLog(@"User with facebook logged in!");
            //[self performSegueWithIdentifier:@"Login" sender:sender];
        }
        
        [FBRequestConnection startForMeWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
            if (error) {
                NSLog(@"Something went wrong requesting facebook details: %@", [error localizedDescription]);
            }  else {
                NSDictionary<FBGraphUser> *me = (NSDictionary<FBGraphUser> *)result;
                NSLog(@"me: %@",me);
                
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
                        NSLog(@"I hate errors: %@", [error localizedDescription]);
                    } else {
                        NSLog(@"No error, it should've saved");
                        
                        //Whew We're in!
                        [self performSegueWithIdentifier:@"Login" sender:sender];
                    }
                }];
            }
        }];
    }];
}

@end
