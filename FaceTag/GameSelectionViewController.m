//
//  GameSelectionViewController.m
//  FaceTag
//
//  Created by Colin Tremblay on 1/27/14.
//  Copyright (c) 2014 GrinnellAppDev. All rights reserved.
//

#import "GameSelectionViewController.h"

@interface GameSelectionViewController ()

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
    
    self.tableView.contentInset = UIEdgeInsetsMake(64, 0, 0, 0);
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
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
    // NSLog(@"count: %d", self.modalArray.count);

    return self.modalArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"GameSelectionCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];

    // Configure the cell...
    PFObject *game = [self.modalArray objectAtIndex:indexPath.row];
    cell.textLabel.text = game[@"name"];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    PFObject *selectedGame = [self.modalArray objectAtIndex:indexPath.row];
    NSData *imageData = UIImagePNGRepresentation(self.tagImage);
    PFUser *currentUser = [PFUser currentUser];
    NSDictionary *pairings = selectedGame[@"pairings"];
    NSString *targetUserId = [pairings objectForKey:[[PFUser currentUser] objectId]];
    PFQuery *targetUserQuery = [PFUser query];
    [targetUserQuery getObjectInBackgroundWithId:targetUserId block:^(PFObject *object, NSError *error) {
        if (!error) {
            PFUser *targetUser;
            targetUser = (PFUser *)object;
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
                    } else {
                        // NSLog(@"%@", error);
                    }
                }];
            }];
        }
    }];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
