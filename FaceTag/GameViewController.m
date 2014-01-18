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
    [self showTagPhotoPicker];
}

- (void)uploadPhotoTag
{
    if (self.tagImage) {
        NSLog(@"Uploading tag image!!");
        
        NSData *imageData = UIImagePNGRepresentation(self.tagImage);
        PFFile *imageFile = [PFFile fileWithName:@"phototag.png" data:imageData];
        
        [imageFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            
            //Create the PhotoTag object.
            PFObject *photoTag = [PFObject objectWithClassName:@"PhotoTag"];
            photoTag[@"sender"] = [PFUser currentUser];
            photoTag[@"photo"] = imageFile;
            photoTag[@"confirmation"] = @0;
            
            [photoTag saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (!error) {
                    NSLog(@"photo tag saved!!");
                }
            }];
        }];
    } else {
        //This should happen. Since there should be a tag image by the time this is called!!!
    }
}

#pragma mark - UIImagePickerDelegate Stuff.

- (void)showTagPhotoPicker
{
    
    if (!self.imagePickerController) {
        self.imagePickerController = [[UIImagePickerController alloc] init];
        self.imagePickerController.delegate = self;
        self.imagePickerController.allowsEditing = YES;
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

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    
    NSString *mediaType = info[UIImagePickerControllerMediaType];
    if ([mediaType isEqualToString:(NSString *)kUTTypeImage]) {
        UIImage *image = info[UIImagePickerControllerEditedImage];
        self.tagImage = [self resizeImage:image toWidth:250 andHeight:250];
        
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
