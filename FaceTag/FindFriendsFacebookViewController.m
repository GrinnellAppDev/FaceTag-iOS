//
//  FindFriendsFacebookViewController.m
//  FaceTag
//
//  Created by Maijid Moujaled on 2/2/14.
//  Copyright (c) 2014 GrinnellAppDev. All rights reserved.
//

#import "FindFriendsFacebookViewController.h"

@interface FindFriendsFacebookViewController ()
@property (nonatomic, strong) NSArray *facebookFriendsOnFaceTag;
@property (nonatomic, strong) NSMutableArray *facebookFriendsNOTonFaceTag;
@property (weak, nonatomic) IBOutlet UITableView *theTableView;
@end

@implementation FindFriendsFacebookViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated
{
    [FBRequestConnection startForMyFriendsWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if (error) {
            NSLog(@"Really hate errors: %@", [error localizedDescription]);
        } else {
            
           // NSLog(@"result: %@", result);
            NSArray *data = result[@"data"];
            NSMutableArray *facebookIds = [[NSMutableArray alloc] initWithCapacity:data.count];
            for (NSDictionary *friendData in data) {
                [facebookIds addObject:friendData[@"id"]];
            }
           // NSLog(@"Fb friends: %@", facebookIds);
            
            //Need a mutable Array of fbFriendsIDs.
            NSMutableArray *fbFriendsIDArray = [NSMutableArray arrayWithArray:facebookIds];
            PFQuery *query = [PFUser query];
            [query whereKey:@"facebookId" containedIn:fbFriendsIDArray];
            query.cachePolicy = kPFCachePolicyCacheThenNetwork;
            [query  findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                    NSLog(@"fb friends: %@", objects);
                
                
                    self.facebookFriendsOnFaceTag = objects;
                NSMutableArray *fbIdsFriendsUsingFaceTag = [NSMutableArray new];
                
                for ( PFUser *friend in objects) {
                    [fbIdsFriendsUsingFaceTag addObject:friend[@"facebookId"]];
                }
                
                [FBRequestConnection startForMyFriendsWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                    if (error) {
                        NSLog(@"Really hate errors: %@", [error localizedDescription]);
                    } else {
                        NSArray *data = result[@"data"];
                        self.facebookFriendsNOTonFaceTag = [[NSMutableArray alloc] initWithArray:data];
                        
                        //Loop through array of dicts.
                        for (NSDictionary *friendDict in data) {
                            
                            //If this friend is also on voice
                            if ([fbIdsFriendsUsingFaceTag containsObject:friendDict[@"id"]]) {
                                //Remove from fbFriendsNOTonVoice.
                                [self.facebookFriendsNOTonFaceTag removeObject:friendDict];
                            }
                        }
                        
                        //Sort all these dictionaries.
                        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
                        [self.facebookFriendsNOTonFaceTag sortUsingDescriptors:@[sortDescriptor]];
                    
                        [self.theTableView reloadData];

                    }
                }];

            }];
        }
    }];
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return 5;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    cell.textLabel.text = @"Facebook friends go here";
    return cell;
}

@end
