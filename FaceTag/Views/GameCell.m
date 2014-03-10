//
//  GameCell.m
//  FaceTag
//
//  Created by Maijid Moujaled on 2/24/14.
//  Copyright (c) 2014 GrinnellAppDev. All rights reserved.
//

#import "GameCell.h"

@implementation GameCell


- (void)awakeFromNib
{

    self.notificationView.layer.cornerRadius = 13.f;
    
    self.notificationLabel.numberOfLines = 1;
    self.notificationLabel.adjustsFontSizeToFitWidth = YES;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        
        /*
        itemImageView.layer.borderWidth = 1.0f;
        itemImageView.layer.borderColor = [UIColor concreteColor].CGColor;
        itemImageView.layer.masksToBounds = NO;
        itemImageView.clipsToBounds = YES;
         */ 
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
