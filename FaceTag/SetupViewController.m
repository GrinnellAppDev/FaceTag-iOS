//
//  SetupViewController.m
//  FaceTag
//
//  Created by Colin Tremblay on 1/17/14.
//  Copyright (c) 2014 GrinnellAppDev. All rights reserved.
//

#import "SetupViewController.h"

@interface SetupViewController ()

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
    
    self.usersToInvite = [[NSMutableArray alloc] init];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    NSLog(@"uti: %@", self.usersToInvite); 
}


- (IBAction)create {
    
    PFObject *game = [PFObject objectWithClassName:@"Game"];
    
    
    NSString *gameName = [NSString stringWithFormat:@"%@'s game", [[PFUser currentUser] objectForKey:@"firstName"]];
    
    int pointsToWin = [self.pointsToWin.text intValue];
    
    NSMutableDictionary *scoreboard = [[NSMutableDictionary alloc] init];
    
    for (NSString *userId in self.usersToInvite) {
        [scoreboard setObject:@0 forKey:userId];
    }
    
    game[@"name"] = gameName;
    game[@"participants"] = self.usersToInvite;
    game[@"pointsToWin"] = @(pointsToWin);
    game[@"scoreboard"] = scoreboard;
    game[@"unconfirmedPhotoTags"] = [[NSArray alloc] init];
    
    // TODO (DrJid): Set timePerTurn stuff.
    game[@"timePerTurn"] = @20;
    
    [game saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (!error) {
            NSLog(@"SAvedddd!!!");
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
    long longRow = (long)row;
    return [NSString stringWithFormat:@"%ld", longRow + 1];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    long longRow = (long)row;
    self.pointsToWin.text = [NSString stringWithFormat:@"%ld", longRow + 1];
}

@end
