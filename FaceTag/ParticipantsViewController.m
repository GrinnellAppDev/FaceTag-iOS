//
//  ParticipantsViewController.m
//  FaceTag
//
//  Created by Colin Tremblay on 1/18/14.
//  Copyright (c) 2014 GrinnellAppDev. All rights reserved.
//

#import "ParticipantsViewController.h"
#import "DeckViewController.h"

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
    
    [self.view addObserver:self forKeyPath:@"frame" options:0 context:NULL];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    DeckViewController *deckVC = (DeckViewController *)self.parentViewController;
    deckVC.resize = YES;
}

- (void)dealloc {
    [self.view removeObserver:self forKeyPath:@"frame"];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    DeckViewController *deckVC = (DeckViewController *)self.parentViewController;
    self.tableView.contentInset = UIEdgeInsetsMake(deckVC.resize * 64, 0, 0, 0);
    
    PFQuery *userQuery = [PFUser query];
    [userQuery whereKey:@"objectId" containedIn:self.participantsIDs];
    [userQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            PFQuery *gameQuery = [PFQuery queryWithClassName:@"Game"];
            [gameQuery whereKey:@"objectId" equalTo:self.game.objectId];
            [gameQuery findObjectsInBackgroundWithBlock:^(NSArray *gameObjects, NSError *error) {
                if (!error) {
                    self.game = gameObjects.firstObject;
                    for (PFUser *user in objects) {
                        user[@"score"] = [self.game[@"scoreboard"] objectForKey:user.objectId];
                    }
                    self.participants = [[NSMutableArray alloc] initWithArray:objects];
                    
                    //Sort the participants.
                    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"score" ascending:NO];
                    [self.participants sortUsingDescriptors:@[sortDescriptor]];

                    [self.tableView reloadData];
                }
            }];
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

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return self.participants.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"ParticipantsCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    PFUser *user = [self.participants objectAtIndex:indexPath.row];
    
    cell.textLabel.text = [NSString stringWithFormat:@"\t\t%@", user[@"fullName"]];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", user[@"score"]];
    
    // Configure the cell...
    
    return cell;
}

@end
