//
//  InviteToGameTableViewController.h
//  FaceTag
//
//  Created by Maijid Moujaled on 1/18/14.
//  Copyright (c) 2014 GrinnellAppDev. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface InviteToGameTableViewController : UITableViewController

// We have a friendsRelation which we use to keep track of friends of a particular user.
@property (nonatomic, strong) PFRelation *friendsRelation;
@property (nonatomic, strong) NSArray *friends;

@end
