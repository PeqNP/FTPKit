//
//  MainViewController.m
//  FTPKitSample
//
//  Created by Eric Chamberlain on 3/10/14.
//  Copyright (c) 2014 Upstart Illustration LLC. All rights reserved.
//

#import "MainViewController.h"
#import "GeneralTest.h"
#import "HandleTest.h"
#import "PerformanceTest.h"

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
    [button setTitle:@"Start Tests" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(startTests) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
}

- (void)startTests
{
    [self testGeneral];
    //[self testHandle];
}

- (void)testGeneral
{
    self.testCase = [[GeneralTest alloc] init];
    testCase.delegate = self;
    [testCase run];
}

- (void)testHandle
{
    self.testCase = [[HandleTest alloc] init];
    testCase.delegate = self;
    [testCase run];
}

- (void)testPerformance
{
    self.testCase = [[PerformanceTest alloc] init];
    testCase.delegate = self;
    [testCase run];
}

// TestCaseDelegate

- (void)testCaseDidFinish:(TestCase *)aTestCase
{
    NSLog(@"END %@", NSStringFromClass([aTestCase class]));
    if ([aTestCase isKindOfClass:[GeneralTest class]])
    {
        [self testPerformance];
    }
    else if ([aTestCase isKindOfClass:[PerformanceTest class]])
    {
        [self testHandle];
    }
    else
    {
        self.testCase = nil;
    }
}

@end
