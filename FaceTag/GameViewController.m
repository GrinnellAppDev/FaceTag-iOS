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
#import <MobileCoreServices/UTCoreTypes.h>
#import "DeckViewController.h"
#import "UIImageView+UIActivityIndicatorForSDWebImage.h"

@interface GameViewController  () <UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (nonatomic, assign) BOOL tappedCamera;
@property (nonatomic, assign) BOOL tappedDelete;
@property (nonatomic, strong) UIImagePickerController *imagePickerController;
@property (nonatomic, strong) UIImage *tagImage;
@property (nonatomic, strong) PFUser *targetUser;
@property (nonatomic, weak) IBOutlet UIImageView *targetProfileImageView;
@property (nonatomic, weak) IBOutlet UILabel *otherLabel;
@property (nonatomic, weak) IBOutlet UILabel *targetNameLabel;
@property (nonatomic, weak) IBOutlet UIButton *camera;
@property (nonatomic, weak) IBOutlet UIButton *deleteBtn;
@property (weak, nonatomic) IBOutlet UILabel *targetLabel;

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
    
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"navigation_arrow.png"] style:UIBarButtonItemStyleBordered target:self action:@selector(popToLobbyVC:)];
    self.navigationItem.leftBarButtonItem = backButton;
    
    UIBarButtonItem *menuButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"sidebar.png"] style:UIBarButtonItemStyleBordered target:self action:@selector(menuButtonPressed:)];
    self.navigationItem.rightBarButtonItem = menuButton;
    
    UIFont *ralewayfont = [UIFont fontWithName:@"Raleway-Thin" size:40.0f];
    NSLog(@"the font: %@", ralewayfont);
    self.targetLabel.font = ralewayfont;
    
    self.targetNameLabel.text = @""; // Storyboard has 'Colin Tremblay'
    /*
    for (NSString* family in [UIFont familyNames])
    {
        NSLog(@"%@", family);
        
        for (NSString* name in [UIFont fontNamesForFamilyName: family])
        {
            NSLog(@"  %@", name);
        }
    }
    */
    
    
}

- (void)popToLobbyVC:(id)sender {
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (IBAction)menuButtonPressed:(id)sender {
    [self.viewDeckController toggleRightViewAnimated:YES];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.tappedCamera = NO;
    
    self.targetProfileImageView.layer.cornerRadius = 115;
    self.targetProfileImageView.layer.borderColor = [UIColor colorWithWhite:203.0f/255.0f alpha:1.0].CGColor;
    self.targetProfileImageView.layer.borderWidth = 5.0f;
    self.targetProfileImageView.layer.masksToBounds = YES;
    
    PFQuery *gameQuery = [PFQuery queryWithClassName:@"Game"];
    [gameQuery whereKey:@"objectId" equalTo:self.game.objectId];
    [gameQuery includeKey:@"winner"];
    [gameQuery findObjectsInBackgroundWithBlock:^(NSArray *gameObjects, NSError *error) {
        if (!error) {
            self.game = gameObjects.firstObject;
            // If the game is over, set up the screen
            if (self.game[@"gameOver"]) {
                self.targetUser = self.game[@"winner"];
                self.otherLabel.text = @"The winner is";
                self.camera.hidden = YES;
                self.deleteBtn.hidden = NO;
                NSString *profileString = self.targetUser[@"profilePictureURL"];
                NSURL *profileURL = [NSURL URLWithString:profileString];
                
                [self.targetProfileImageView setImageWithURL:profileURL usingActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
                
               [self.targetProfileImageView setImageWithURL:profileURL
                                            placeholderImage:nil usingActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
                
                self.targetNameLabel.text = self.targetUser[@"fullName"];
            }
        }
    }];
    
    PFUser *currentUser = [PFUser currentUser];
    NSDictionary *pairings = self.game[@"pairings"];
    NSString *targetUserId = pairings[currentUser.objectId];
    
    // Check if user has already submitted a picture during this round
    NSDictionary *submittedDict = self.game[@"submitted"];
    BOOL submitted = [[submittedDict objectForKey:[[PFUser currentUser] objectId]] boolValue];
    DeckViewController *deckVC = (DeckViewController *)self.parentViewController;
    if (submitted || deckVC.cameraNeedsHiding) {
        self.camera.hidden = YES;
    } else {
        self.camera.hidden = NO;
    }
    
    //Fetch the target User.
    PFQuery *targetUserQuery = [PFUser query];
    [targetUserQuery getObjectInBackgroundWithId:targetUserId block:^(PFObject *object, NSError *error) {
        // Only need to set the target stuff if the game isn't over
        if (!self.game[@"gameOver"] && !error) {
            self.targetUser = (PFUser *)object;
            
            NSString *profileString = self.targetUser[@"profilePictureURL"];
            NSURL *profileURL = [NSURL URLWithString:profileString];
            [self.targetProfileImageView setImageWithURL:profileURL usingActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            
            self.targetNameLabel.text = self.targetUser[@"fullName"];
        }
    }];
}

- (IBAction)deleteGame:(id)sender {
    if (self.tappedDelete) {
        return;
    }
    
    self.tappedDelete = YES;
    [self.game deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
    }];
    PFQuery *picQuery = [PFQuery queryWithClassName:@"PhotoTag"];
    [picQuery whereKey:@"game" equalTo:self.game.objectId];
    [picQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            for (PFObject *pic in objects) {
                [pic deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                }];
            }
        }
    }];
    [self popToLobbyVC:sender];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)showCamera:(id)sender {
    if (self.tappedCamera) {
        return;
    }
    
    self.tappedCamera = YES;
    DeckViewController *deckVC = (DeckViewController *)self.parentViewController;
    deckVC.resize = YES;
    [self showTagPhotoPicker];
}

- (void)uploadPhotoTag {
    NSData *imageData = UIImagePNGRepresentation(self.tagImage);
    PFUser *currentUser = [PFUser currentUser];
    NSString *fileName =  [NSString stringWithFormat:@"%@-%@", currentUser[@"firstName"], self.targetUser[@"firstName"]];
    PFFile *imageFile = [PFFile fileWithName:fileName data:imageData];
    
    [imageFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        
        //Create the PhotoTag object.
        PFObject *photoTag = [PFObject objectWithClassName:@"PhotoTag"];
        photoTag[@"sender"] = [PFUser currentUser];
        photoTag[@"photo"] = imageFile;
        photoTag[@"target"] = self.targetUser;
        photoTag[@"game"] = [self.game objectId];
        [photoTag saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (!error) {
                // NSLog(@"photo tag saved!!");
            } else {
                // NSLog(@"%@", error);
            }
        }];
    }];
}

#pragma mark - UIImagePickerDelegate Stuff.
- (void)showTagPhotoPicker {
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
        self.tagImage =  [self resizeImage:image toWidth:320 andHeight:newHeight];
        
        // Hide the camera to prevent multiple submissions per round
        DeckViewController *deckVC = (DeckViewController *)self.parentViewController;
        deckVC.cameraNeedsHiding = YES;
        
        [self uploadPhotoTag];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
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
