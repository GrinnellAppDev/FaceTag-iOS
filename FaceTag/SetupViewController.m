//
//  SetupViewController.m
//  FaceTag
//
//  Created by Colin Tremblay on 1/17/14.
//  Copyright (c) 2014 GrinnellAppDev. All rights reserved.
//

#import "SetupViewController.h"

@interface SetupViewController ()

@property (nonatomic, strong) NSMutableArray *timePerTurnDataPickerArray;

@property (weak, nonatomic) IBOutlet UIPickerView *pointsPicker;
@property (weak, nonatomic) IBOutlet UIPickerView *timePerTurnPicker;

@end

@implementation SetupViewController
{
    BOOL _pointsPickerVisible;
    BOOL _timePerTurnPickerVisible;
    
    int pointsToWin;
    NSString *timePerTurnString;
    
}

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
    
    _pointsPickerVisible = NO;
    self.pointsPicker.hidden = YES;
    
    _timePerTurnPickerVisible = NO;
    self.timePerTurnPicker.hidden = YES;
    
    //Default points to win and timer per turn. These are the default values set in the storyboard as well
    pointsToWin = 5;
    timePerTurnString = @"2 Hrs";
    
    self.usersToInvite = [[NSMutableArray alloc] init];
    
    self.timePerTurnDataPickerArray = [[NSMutableArray alloc] initWithObjects:@"20 Min", @"1 Hr", @"2 Hrs", @"6 Hrs", @"12 Hrs", @"24 Hrs", @"2 Days", @"1 Week", nil];
    
    self.gameName.text = [NSString stringWithFormat:@"%@'s game", [[PFUser currentUser] objectForKey:@"firstName"]];
    
    //Set the background of the TableView
    UIImageView *backgroundImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"game_background_light"]];
    [backgroundImageView setFrame:self.tableView.frame];
    self.tableView.backgroundView = backgroundImageView;
    
    //Hide all visible pickers when the keyboard is presented.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideVisiblePickers) name:UIKeyboardWillShowNotification object:nil];
    
    //Tapping on the backgroundView should dismiss the keyboard and hide all pickers.
    UITapGestureRecognizer *backgroundTappedGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboardAndPicker)];
    [self.tableView  addGestureRecognizer:backgroundTappedGesture];
    
    //This enables the cells to still be tappable
    backgroundTappedGesture.cancelsTouchesInView = NO;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self updateInvitedFriendCountDetailLabel];
}

- (void)hideKeyboardAndPicker{
    [self.view endEditing:YES];
    //[self hideVisiblePickers];
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
    
    NSArray *participants = [NSArray arrayWithObject:[[PFUser currentUser] objectId]];
    game[@"participants"] = participants;
    game[@"name"] = self.gameName.text;
    game[@"invitedUsers"] = self.usersToInvite;
    game[@"pointsToWin"] = @(pointsToWin);
    
    NSArray *arrayOfTimes = [[NSArray alloc] initWithObjects:@20, @60, @120, @360, @720, @1440, @2880, @10080, nil];
    
    game[@"timePerTurn"] = [arrayOfTimes objectAtIndex:[self.timePerTurnDataPickerArray indexOfObject:timePerTurnString]];
    
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
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return 8;
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    
    if (pickerView == self.timePerTurnPicker) {
        return self.timePerTurnDataPickerArray[row];
    } else {
        long longRow = (long)row;
        return [NSString stringWithFormat:@"%ld", longRow + 1];
    }
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger) component {
    
    NSIndexPath *indexPath = [self getIndexPathForPickerView:pickerView];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    cell.detailTextLabel.textColor = cell.detailTextLabel.tintColor;

    if (pickerView == self.pointsPicker) {
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%ld", row + 1];
        pointsToWin = (int)row + 1;
        
    } else {
        //It is the time per turn picker view
        timePerTurnString = self.timePerTurnDataPickerArray[row];
        cell.detailTextLabel.text = timePerTurnString;
    }
}

- (void)updateInvitedFriendCountDetailLabel
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    NSString *friendCount;
    
    if (self.usersToInvite.count > 0) {
        
        //Use primitive pluralization
        friendCount = [NSString stringWithFormat:@"%ld friend%@",  self.usersToInvite.count, (self.usersToInvite.count == 1 ? @"" : @"s")];
    } else {
        friendCount = @"";
    }

    cell.detailTextLabel.text = friendCount;
}

- (void)inviteUsersError {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error!" message:@"You cannot start a game without inviting anyone!" delegate:Nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [alert show];
}


#pragma mark - UITableView Methods
- (CGFloat)tableView:(UITableView *)theTableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 1 && indexPath.row == 1) {
        return _pointsPickerVisible ? 217.0f : 0;
    } else if (indexPath.section == 1 & indexPath.row == 3) {
        NSLog(@"_timeperturn: %d", _timePerTurnPickerVisible);
        return _timePerTurnPickerVisible ? 217.0f : 0;
    } else {
        return 44.0f;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0 && indexPath.section == 1) {
        if (!_pointsPickerVisible) {
            [self showPicker:self.pointsPicker];
        } else {
            [self hidePicker:self.pointsPicker];
        }
        return;
    }
    
    if (indexPath.row == 2 && indexPath.section == 1) {
        NSLog(@"Tapped!!! %d", _timePerTurnPickerVisible);
        if (!_timePerTurnPickerVisible) {
            [self showPicker:self.timePerTurnPicker];
        } else {
            [self hidePicker:self.timePerTurnPicker];
        }
        return;
    }
    
    [self hidePicker:self.pointsPicker];
    [self hidePicker:self.timePerTurnPicker];
}



- (void)showPicker:(UIPickerView *)pickerView
{
    [self hideVisiblePickers];
    [self.view endEditing:YES];
    
    if (pickerView == self.pointsPicker) {
        _pointsPickerVisible = YES;
        [pickerView selectRow:pointsToWin - 1 inComponent:0 animated:NO];
    }
    
    if (pickerView == self.timePerTurnPicker) {
        _timePerTurnPickerVisible = YES;
        
         NSUInteger index = [self.timePerTurnDataPickerArray indexOfObject:timePerTurnString];
        [pickerView selectRow:index inComponent:0 animated:NO];
    }
    
    
    NSIndexPath *indexPath = [self  getIndexPathForPickerView:pickerView];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    cell.detailTextLabel.textColor = cell.detailTextLabel.tintColor;
    
    
    [self.tableView beginUpdates];
    [self.tableView endUpdates];
    
    pickerView.hidden = NO;
    pickerView.alpha = 0.0f;
    [UIView animateWithDuration:0.25 animations:^{
        pickerView.alpha = 1.0f;
    }];
    
    NSIndexPath *pickerIndexPath = [NSIndexPath indexPathForRow:indexPath.row + 1 inSection:indexPath.section];
    [self.tableView scrollToRowAtIndexPath:pickerIndexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
    
}

- (void)hidePicker:(UIPickerView *)pickerView
{
    if (_pointsPickerVisible) {
        _pointsPickerVisible = NO;
    }
    
    if (_timePerTurnPickerVisible) {
        _timePerTurnPickerVisible = NO;
    }
    
    NSIndexPath *indexPath = [self getIndexPathForPickerView:pickerView];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    cell.detailTextLabel.textColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5f];
    
    [self.tableView beginUpdates];
    [self.tableView endUpdates];
    
    [UIView animateWithDuration:0.25 animations:^{
        pickerView.alpha = 0.0f;
    } completion:^(BOOL finished) {
        pickerView.hidden = YES;
    }];
}

- (void)hideVisiblePickers
{
    if (_timePerTurnPickerVisible) {
        [self hidePicker:self.timePerTurnPicker];
    }
    
    if (_pointsPickerVisible) {
        [self hidePicker:self.pointsPicker];
    }
}

- (NSIndexPath *)getIndexPathForPickerView:(UIPickerView *)pickerView
{
    if (pickerView == self.pointsPicker ) {
        return [NSIndexPath indexPathForRow:0 inSection:1];
    } else  {
        return [NSIndexPath indexPathForRow:2 inSection:1];
    }
}


@end
