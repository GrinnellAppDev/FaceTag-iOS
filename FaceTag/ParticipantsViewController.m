//
//  ParticipantsViewController.m
//  FaceTag
//
//  Created by Colin Tremblay on 1/18/14.
//  Copyright (c) 2014 GrinnellAppDev. All rights reserved.
//

#import "ParticipantsViewController.h"

@interface ParticipantsViewController ()

@end

@implementation ParticipantsViewController

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
    
    self.tableView.contentInset = UIEdgeInsetsMake(60, 0, 0, 0);

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    PFQuery *userQuerry = [PFUser query];
    [userQuerry whereKey:@"objectId" containedIn:self.participantsIDs];
    [userQuerry findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            for (PFUser *user in objects) {
                user[@"score"] = [self.game[@"scoreboard"] objectForKey:user.objectId];
            }
            
            self.participants = [[NSArray alloc] initWithArray:objects];
            [self.tableView reloadData];
        }
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source
- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [NSString stringWithFormat:@"\t\tRound #%@", self.game[@"round"]];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return self.participants.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"ParticipantsCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    PFUser *user = [self.participants objectAtIndex:indexPath.row];

    cell.textLabel.text = [NSString stringWithFormat:@"\t\t%@", user[@"fullName"]];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", user[@"score"]];
    
    // Configure the cell...
    
    return cell;
}

@end
