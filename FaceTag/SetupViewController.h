//
//  SetupViewController.h
//  FaceTag
//
//  Created by Colin Tremblay on 1/17/14.
//  Copyright (c) 2014 GrinnellAppDev. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SetupViewController : UITableViewController <UIPickerViewDataSource, UIPickerViewDelegate, UITextFieldDelegate>

@property (nonatomic, strong) IBOutlet UITextField *gameName;

- (IBAction)cancel;
- (IBAction)create;

@property (nonatomic, strong) NSMutableArray *usersToInvite;

@end
