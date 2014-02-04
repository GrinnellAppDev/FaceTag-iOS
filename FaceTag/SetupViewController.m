//
//  SetupViewController.m
//  FaceTag
//
//  Created by Colin Tremblay on 1/17/14.
//  Copyright (c) 2014 GrinnellAppDev. All rights reserved.
//

#import "SetupViewController.h"

@interface SetupViewController ()

@property (nonatomic, strong) NSMutableArray *pickerArray;

@end

@implementation SetupViewController

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
    
    UIPickerView *pickerView = [[UIPickerView alloc] init];
    pickerView.dataSource = self;
    pickerView.delegate = self;
    
    //Default to 5
    [pickerView selectRow:4 inComponent:0 animated:NO];
    
    self.pointsToWin.inputView = pickerView;
    
    UIPickerView *otherPickerView = [[UIPickerView alloc] init];
    otherPickerView.dataSource = self;
    otherPickerView.delegate = self;
    self.timePerTurn.inputView = otherPickerView;
    [otherPickerView selectRow:2 inComponent:0 animated:NO];
    
    self.usersToInvite = [[NSMutableArray alloc] init];
    
    self.pickerArray = [[NSMutableArray alloc] initWithObjects:@"1 Min", @"5 Min", @"15 Min", @"1 Hr", @"2 Hrs", @"6 Hrs", @"12 Hrs", @"24 Hrs", @"2 Days", @"1 Week", nil];
    self.gameName.text = [NSString stringWithFormat:@"%@'s game", [[PFUser currentUser] objectForKey:@"firstName"]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)create {
    if (self.usersToInvite.count == 0) {
        [self inviteUsersError];
        return;
    }
    
    PFObject *game = [PFObject objectWithClassName:@"Game"];
    int pointsToWin = [self.pointsToWin.text intValue];
    [self.usersToInvite addObject:[PFUser currentUser].objectId];
    
    game[@"name"] = self.gameName.text;
    game[@"participants"] = self.usersToInvite;
    game[@"pointsToWin"] = @(pointsToWin);
    
    NSArray *arrayOfTimes = [[NSArray alloc] initWithObjects:@1, @5, @15, @60, @120, @360, @720, @1440, @2880, @10080, nil];
    game[@"timePerTurn"] = [arrayOfTimes objectAtIndex:[self.pickerArray indexOfObject:self.timePerTurn.text]];
    
    [game saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (!error) {
            //NSLog(@"Created new game.");
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }];
}

- (IBAction)cancel {
    [self dismissViewControllerAnimated:YES completion:nil];
}

# pragma mark - PickerView methods
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return 10;
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    if (self.timePerTurn.isEditing) {
        return [self.pickerArray objectAtIndex:row];
    }
    
    long longRow = (long)row;
    return [NSString stringWithFormat:@"%ld", longRow + 1];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if (self.timePerTurn.isEditing) {
        self.timePerTurn.text = [self.pickerArray objectAtIndex:row];
    } else {
        long longRow = (long)row;
        self.pointsToWin.text = [NSString stringWithFormat:@"%ld", longRow + 1];
    }
}

- (void)inviteUsersError {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error!" message:@"You cannot start a game without inviting anyone!" delegate:Nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [alert show];
}

@end
