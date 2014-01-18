//
//  ParticipantsViewController.h
//  FaceTag
//
//  Created by Colin Tremblay on 1/18/14.
//  Copyright (c) 2014 GrinnellAppDev. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ParticipantsViewController : UITableViewController

@property (nonatomic, strong) NSArray *participantsIDs;
@property (nonatomic, strong) NSArray *participants;
@property (nonatomic, strong) PFObject *game;

@end
