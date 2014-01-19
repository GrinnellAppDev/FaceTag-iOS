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

@interface GameViewController  () <UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (nonatomic, strong) UIImagePickerController *imagePickerController;
@property (nonatomic, strong) UIImage *tagImage;
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
}

- (void)popToLobby:(id)sender {
    [self.navigationController popToViewController:[[self.navigationController viewControllers] objectAtIndex:1] animated:YES];
}

- (IBAction)menuButtonPressed:(id)sender {
    DeckViewController *deckVC = (DeckViewController *)self.parentViewController;
    [deckVC toggleRightViewAnimated:YES];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"navigation_arrow.png"] style:UIBarButtonItemStyleBordered target:self action:@selector(popToLobby:)];
    self.navigationItem.leftBarButtonItem = backButton;
    
    UIBarButtonItem *menuButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"sidebar.png"] style:UIBarButtonItemStyleBordered target:self action:@selector(menuButtonPressed:)];
    self.navigationItem.rightBarButtonItem = menuButton;
    
    self.targetProfileImageView.layer.cornerRadius = 40;
    self.targetProfileImageView.layer.masksToBounds = YES;
    
    // TODO (DrJid): Set the target user correctly!
    NSLog(@"game: %@", self.game); 
    PFUser *currentUser = [PFUser currentUser];
    NSDictionary *pairings = self.game[@"pairings"];
    NSLog(@"pa: %@", pairings); 
    NSString *targetUserId = pairings[currentUser.objectId];
    NSLog(@"targuserid: %@", targetUserId); 
    
    //Fetch the target User.
    PFQuery *targetUserQuery = [PFUser query];
    [targetUserQuery getObjectInBackgroundWithId:targetUserId block:^(PFObject *object, NSError *error) {
        PFUser *targetUser = (PFUser *)object;
        
        NSString *profileString = targetUser[@"profilePictureURL"];//  [[PFUser currentUser] objectForKey:@"profilePictureURL"];
        NSURL *profileURL = [NSURL URLWithString:profileString];
        [self.targetProfileImageView setImageWithURL:profileURL];
        
        self.targetNameLabel.text = targetUser[@"fullName"]; // [[PFUser currentUser] objectForKey:@"fullName"];

    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)showCamera:(id)sender {
    [self showTagPhotoPicker];
}

- (void)uploadPhotoTag
{
    if (self.tagImage) {
        NSLog(@"Uploading tag image!!");
        
        NSData *imageData = UIImagePNGRepresentation(self.tagImage);
        PFUser *currentUser = [PFUser currentUser];
        NSString *fileName =  [NSString stringWithFormat:@"%@-%@", currentUser[@"firstName"], currentUser[@"lastName"]];
        PFFile *imageFile = [PFFile fileWithName:fileName data:imageData];
        
        [imageFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            
            //Create the PhotoTag object.
            PFObject *photoTag = [PFObject objectWithClassName:@"PhotoTag"];
            photoTag[@"sender"] = [PFUser currentUser];
            photoTag[@"photo"] = imageFile;
            photoTag[@"confirmation"] = @0;
            photoTag[@"rejection"] = @0;
            photoTag[@"usersArray"] = [[NSArray alloc] initWithObjects:[PFUser currentUser], nil];
            
            // TODO - Get the target's name here
            photoTag[@"target"] = [PFUser currentUser];
            [photoTag saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (!error) {
                    NSLog(@"photo tag saved!!");
                    NSMutableArray *tagsArray = [[NSMutableArray alloc]  initWithArray:self.game[@"unconfirmedPhotoTags"]];
                    [tagsArray addObject:photoTag];
                    [self.game setObject:tagsArray forKey:@"unconfirmedPhotoTags"];
                    [self.game saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                        if(!error)
                            NSLog(@"Game updated");
                    }];
                }
            }];
        }];
    } else {
        //This should happen. Since there should be a tag image by the time this is called!!!
    }
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

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    
    NSString *mediaType = info[UIImagePickerControllerMediaType];
    if ([mediaType isEqualToString:(NSString *)kUTTypeImage]) {
        UIImage *image = info[UIImagePickerControllerOriginalImage];
        
        //Get the ratio and scale the height according to that ratio. 
        int ratio = image.size.width / 320.0;
        int newHeight = image.size.height / ratio;
        self.tagImage =  [self resizeImage:image toWidth:320 andHeight:newHeight];

        [self uploadPhotoTag];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (UIImage *)resizeImage:(UIImage *)image toWidth:(float)width andHeight:(float)height
{
    CGSize newSize = CGSizeMake(width, height);
    CGRect newRectangle = CGRectMake(0, 0, width, height);
    
    UIGraphicsBeginImageContext(newSize);
    [image drawInRect:newRectangle];
    UIImage *resizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return resizedImage;
}

@end
