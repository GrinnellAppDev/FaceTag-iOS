//
//  GameSelectionViewController.m
//  FaceTag
//
//  Created by Colin Tremblay on 1/27/14.
//  Copyright (c) 2014 GrinnellAppDev. All rights reserved.
//

#import "GameSelectionViewController.h"
#import <MobileCoreServices/UTCoreTypes.h>

@interface GameSelectionViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (nonatomic, strong) UIImagePickerController *imagePickerController;
@property (nonatomic, assign) BOOL notFirstLaunch;
@property (nonatomic, strong) NSIndexPath *checkedIndex;

@end

@implementation GameSelectionViewController

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStyleBordered target:self action:@selector(dismissTableView:)];
    self.navigationItem.leftBarButtonItem = cancelButton;
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (!self.notFirstLaunch) {
        self.notFirstLaunch = YES;
        [self showTagPhotoPicker];
    }
    
    if (self.tagImage) {
        UIBarButtonItem *submitButton = [[UIBarButtonItem alloc] initWithTitle:@"Submit" style:UIBarButtonItemStyleBordered target:self action:@selector(submitPhoto:)];
        self.navigationItem.rightBarButtonItem = submitButton;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dismissTableView:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)submitPhoto:(id)sender {
    if (!self.checkedIndex) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error!" message:@"You must select a game to submit to!"  delegate:nil
                                             cancelButtonTitle:@"Ok"
                                             otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    PFObject *selectedGame = [self.gameArray objectAtIndex:self.checkedIndex.row];
    NSData *imageData = UIImagePNGRepresentation(self.tagImage);
    PFUser *currentUser = [PFUser currentUser];
    PFUser *targetUser = [self.targetDictionary objectForKey:selectedGame[@"name"]];
    NSString *fileName =  [NSString stringWithFormat:@"%@-%@", currentUser[@"firstName"], targetUser[@"firstName"]];
    PFFile *imageFile = [PFFile fileWithName:fileName data:imageData];
    [imageFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        //Create the PhotoTag object.
        PFObject *photoTag = [PFObject objectWithClassName:@"PhotoTag"];
        photoTag[@"sender"] = [PFUser currentUser];
        photoTag[@"photo"] = imageFile;
        photoTag[@"target"] = targetUser;
        photoTag[@"game"] = [selectedGame objectId];
        [photoTag saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (!error) {
                // NSLog(@"photo tag saved!!");
                NSMutableDictionary *submittedDict = selectedGame[@"submitted"];
                [submittedDict setObject:@YES forKey:[currentUser objectId]];
                selectedGame[@"submitted"] = submittedDict;
                [selectedGame save];
            } else {
                // NSLog(@"%@", error);
            }
        }];
    }];
    
    [self dismissTableView:sender];
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    if (self.notFirstLaunch) {
        return 1;
    } else {
        return 0;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return self.gameArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"GameSelectionCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    PFObject *game = [self.gameArray objectAtIndex:indexPath.row];
    cell.textLabel.text = game[@"name"];
    PFUser *target = [self.targetDictionary objectForKey:game[@"name"]];
    cell.detailTextLabel.text = target[@"firstName"];
    cell.accessoryType = UITableViewCellAccessoryNone;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (!self.tagImage) {
        return;
    }
    
    // Uncheck other cell
    if (self.checkedIndex && self.checkedIndex.row != indexPath.row) {
        UITableViewCell *oldCell = [tableView cellForRowAtIndexPath:self.checkedIndex];
        if (UITableViewCellAccessoryCheckmark == oldCell.accessoryType) {
            oldCell.accessoryType = UITableViewCellAccessoryNone;
        }
    }
    
    // Toggle the selected cell
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if (UITableViewCellAccessoryNone == cell.accessoryType) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        self.checkedIndex = indexPath;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
        self.checkedIndex = NULL;
    }
}



#pragma mark - UIImagePickerDelegate Stuff.
- (void)showTagPhotoPicker {
    // Create image picker
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
        [self presentViewController:self.imagePickerController animated:YES completion:nil];
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
