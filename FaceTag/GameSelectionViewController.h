//
//  GameSelectionViewController.h
//  FaceTag
//
//  Created by Colin Tremblay on 1/27/14.
//  Copyright (c) 2014 GrinnellAppDev. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GameSelectionViewController : UITableViewController

@property (nonatomic, strong) NSMutableArray *gameArray;
@property (nonatomic, strong) NSMutableDictionary *targetDictionary;
@property (nonatomic, strong) UIImage *tagImage;

@end
