//
//  BFScanEditVC.m
//  BFScanVCDemo
//
//  Created by Readboy_BFAlex on 2017/6/8.
//  Copyright © 2017年 Readboy_BFAlex. All rights reserved.
//

#import "BFScanEditVC.h"

@interface BFScanEditVC ()<UIAlertViewDelegate>
@property (weak, nonatomic) IBOutlet UIView *navigationBar;
@property (weak, nonatomic) IBOutlet UIButton *backBtn;
@property (weak, nonatomic) IBOutlet UIButton *finishBtn;
@property (weak, nonatomic) IBOutlet UITextField *codeView;

@end

@implementation BFScanEditVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setupViews];
}

#pragma mark - private

- (void)setupViews {
    // 隐藏系统导航栏
    self.navigationController.navigationBar.hidden = YES;
    
    // 设置View的样式
    
    // 添加View的事件
    [self setupBtnAction];
}

- (void)setupBtnAction {
    
    // 返回按钮
    [self.backBtn addTarget:self action:@selector(clickBackBtn:) forControlEvents:UIControlEventTouchUpInside];
    // 确定按钮
    [self.finishBtn addTarget:self action:@selector(clickFinishBtn:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)clickFinishBtn:(UIButton *)btn {
    NSLog(@"%s %d", __func__, __LINE__);
    // 有效判断
    if (self.codeView.text.length <= 0) {
        // 无效
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"温馨提示" message:@"请输入有效条形码" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
        [alert show];
        
        return;
    }
    
    NSDictionary *dict = [[NSDictionary alloc] initWithObjectsAndKeys:self.codeView.text, @"Code", nil];
    NSNotification *noti = [NSNotification notificationWithName:@"ScanEditVCNotification" object:nil userInfo:dict];
    [[NSNotificationCenter defaultCenter] postNotification:noti];
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)clickBackBtn:(UIButton *)btn {
    NSLog(@"%s %d", __func__, __LINE__);
    
    if (self.codeView.text.length > 0) {
        // 提示未保存是否直接退出
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"温馨提示" message:@"条形码还没确定，仍然坚持退出？" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:@"取消", nil];
        [alert show];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSLog(@"%s %d", __func__, __LINE__);
    
    if (0 == buttonIndex) {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

@end
