//
//  ViewController.m
//  BFScanVCDemo
//
//  Created by Readboy_BFAlex on 2017/6/5.
//  Copyright © 2017年 Readboy_BFAlex. All rights reserved.
//

#import "ViewController.h"
#import "BFScanVC.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (IBAction)enterScanVC:(UIButton *)sender {
    BFScanVC *scanVC = [BFScanVC scanVCWithDescription:@"扫描二维码"];
    [self.navigationController pushViewController:scanVC animated:YES];
}

@end
