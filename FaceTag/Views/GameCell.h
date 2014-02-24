//
//  GameCell.h
//  FaceTag
//
//  Created by Maijid Moujaled on 2/24/14.
//  Copyright (c) 2014 GrinnellAppDev. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GameCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *gameNameLabel;
@property (weak, nonatomic) IBOutlet UIView *notificationView;
@property (weak, nonatomic) IBOutlet UILabel *notificationLabel;

@end
