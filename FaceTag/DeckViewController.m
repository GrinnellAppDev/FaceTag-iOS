//
//  DeckViewController.m
//  FaceTag
//
//  Created by Colin Tremblay on 1/18/14.
//  Copyright (c) 2014 GrinnellAppDev. All rights reserved.
//

#import "DeckViewController.h"
#import "GameViewController.h"
#import "ParticipantsViewController.h"

@interface DeckViewController ()

@end

@implementation DeckViewController

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
    self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    
    //Register for notification to pop back
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(goBack) name:@"PopDeckViewBack" object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    GameViewController *gameVC = [self.storyboard instantiateViewControllerWithIdentifier:@"GameViewController"];
    gameVC.game = self.game;
    self.centerController = gameVC;
    
    self.leftController = nil;
    ParticipantsViewController *partsVC = [self.storyboard instantiateViewControllerWithIdentifier:@"ParticipantsViewController"];
    partsVC.participantsIDs = [[NSArray alloc] initWithArray:self.game[@"participants"]];
    partsVC.game = self.game;
    self.rightController = partsVC;
    
    self.title = self.game[@"name"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//- (BOOL)closeRightViewAnimated:(BOOL)animated {
//    NSLog(@"1");
//    return [super closeRightViewAnimated:animated];
//}
//
//- (BOOL)closeRightViewAnimated:(BOOL)animated completion:(IIViewDeckControllerBlock)completed {
//    NSLog(@"2");
//    return [super closeRightViewAnimated:animated completion:completed];
//}
- (BOOL)closeRightViewAnimated:(BOOL)animated duration:(NSTimeInterval)duration completion:(IIViewDeckControllerBlock)completed{
    self.resize = YES;
    return [super closeRightViewAnimated:animated duration:duration completion:completed];
}
//- (BOOL)closeRightViewBouncing:(IIViewDeckControllerBounceBlock)bounced {
//    NSLog(@"4'");
//    return [super closeRightViewBouncing:bounced];
//}
//- (BOOL)closeRightViewBouncing:(IIViewDeckControllerBounceBlock)bounced completion:(IIViewDeckControllerBlock)completed {
//    NSLog(@"5");
//    return [super closeRightViewBouncing:bounced completion:completed];
//}

- (void)goBack
{
    NSLog(@"Go back was called");
    [self.navigationController popToRootViewControllerAnimated:YES];
}


@end
