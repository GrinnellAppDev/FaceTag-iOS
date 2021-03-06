//
//  ConfirmDenyViewController.h
//  FaceTag
//
//  Created by Colin Tremblay on 1/18/14.
//  Copyright (c) 2014 GrinnellAppDev. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ConfirmDenyViewController : UIViewController

@property (nonatomic, strong) PFObject *game;
@property (nonatomic, strong) NSArray *unconfirmedPhotoTags;

- (IBAction)confirm:(id)sender;
- (IBAction)deny:(id)sender;
- (IBAction)notSure:(id)sender;

@end
