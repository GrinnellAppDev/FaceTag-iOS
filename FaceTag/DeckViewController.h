//
//  DeckViewController.h
//  FaceTag
//
//  Created by Colin Tremblay on 1/18/14.
//  Copyright (c) 2014 GrinnellAppDev. All rights reserved.
//

#import "IIViewDeckController.h"

@interface DeckViewController : IIViewDeckController

@property (nonatomic, strong) PFObject *game;
@property (nonatomic, assign) BOOL resize;

@end
