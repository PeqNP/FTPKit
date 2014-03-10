//
//  MainViewController.m
//  FTPKitSample
//
//  Created by Eric Chamberlain on 3/10/14.
//  Copyright (c) 2014 Upstart Illustration LLC. All rights reserved.
//

#import "MainViewController.h"
#import "GeneralTest.h"

@interface MainViewController ()
@property (nonatomic, strong) TestCase *testCase;
@end

@implementation MainViewController

@synthesize testCase;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
	UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    button.frame = CGRectMake(10.0f, 70.0f, 100.0f, 30.0f);
    button.backgroundColor = [UIColor lightGrayColor];
    [button setTitle:@"General" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(testGeneral) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
}

- (void)testGeneral
{
    self.testCase = [[GeneralTest alloc] init];
    testCase.delegate = self;
    [testCase run];
}

// TestCaseDelegate

- (void)testCaseDidFinish:(TestCase *)aTestCase
{
    NSLog(@"END %@", NSStringFromClass([aTestCase class]));
    self.testCase = nil;
}

@end
