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
    [gamesQuery orderByAscending:@"name"];
    
    [gamesQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            self.games = objects;
            [self.tableView reloadData];
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // TODO - Check for photos needing evaluation
    // if (game has photos ready for evaluation)
    //    [self performSegueWithIdentifier:@"ConfirmDeny" sender:nil];
    // else
    [self performSegueWithIdentifier:@"ShowGame" sender:nil];
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
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
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
        
        //Test creating overlay view.
        UIView *overlayView = [[UIView alloc] initWithFrame:self.imagePickerController.view.frame];
        UIImageView *imgView = [[UIImageView alloc] initWithFrame:overlayView.frame];
        imgView.image = [UIImage imageNamed:@"x_image"];
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
        UIImage *image = info[UIImagePickerControllerEditedImage];
        
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
