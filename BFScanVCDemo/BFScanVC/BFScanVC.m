//
//  BFScanVC.m
//  BFScanVCDemo
//
//  Created by Readboy_BFAlex on 2017/6/5.
//  Copyright © 2017年 Readboy_BFAlex. All rights reserved.
//

#import "BFScanVC.h"
#import <AVFoundation/AVFoundation.h>
#import "BFScanEditVC.h"

#define kBorderDistance  20
#define kScanLineSpeed   3

@interface BFScanVC () <AVCaptureMetadataOutputObjectsDelegate> {
    BOOL _sbPreStatus;
    BOOL _barPreStatus;
    
    NSTimer *_scanTimer;
    float _changeValue;
    float _borderDistance;
    float _changeRangeH;
    
    BOOL _startReading;
    AVCaptureSession *_captureSession;
    AVCaptureVideoPreviewLayer *_captureVideoPreviewLayer;
}
@property (weak, nonatomic) IBOutlet UIImageView *scanLine;
@property (weak, nonatomic) IBOutlet UIImageView *scanFrame;
@property (weak, nonatomic) IBOutlet UILabel *scanDescription;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *scanLineToTopConstraint;
@property (weak, nonatomic) IBOutlet UIButton *barLeftBtn;
@property (weak, nonatomic) IBOutlet UIButton *barRightBtn;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *showPreparingView;

@end

@implementation BFScanVC

#pragma mark - life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setupNotification];
}

- (void)viewWillAppear:(BOOL)animated {
    [self setupScanView];
    self.showPreparingView.hidden = NO;
}

- (void)viewDidAppear:(BOOL)animated {
    
    // 检查摄像头是否可用(可用则打开摄像头)
    if ([self checkCameraPromission]) {
        [self configureScanCamera];
    }
    
}

- (void)viewWillDisappear:(BOOL)animated {
    [self recoverView];
}

#pragma mark - public

+ (instancetype)scanVC {
    return [self scanVCWithDescription:nil];
}

+ (instancetype)scanVCWithDescription:(NSString *)descTxt {
    
    BFScanVC *scanVC = [[[NSBundle mainBundle] loadNibNamed:[NSString stringWithFormat:@"%@", [self class]] owner:nil options:nil] lastObject];
    
    if (descTxt.length > 0) {
        scanVC.scanDescription.text = descTxt;
    }
    
    return scanVC;
}

#pragma mark - private

- (void)setupNotification {
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scanEditVCNoti:) name:@"ScanEditVCNotification" object:nil];
}

- (void)scanEditVCNoti:(NSNotification *)noti {
    
    NSString *code = [noti.userInfo objectForKey:@"Code"];
    NSLog(@"code:%@", code);
}

- (void)setupData {
    // 扫描线
    self.scanLineToTopConstraint.constant = kBorderDistance;
    _changeValue = 0;
}

- (void)setupScanView {
    // 隐藏navigationBar
    NSLog(@"bar hidden: %d", self.navigationController.navigationBar.hidden);
    if (!self.navigationController.navigationBar.hidden) {
        _barPreStatus = self.navigationController.navigationBar.hidden;
        self.navigationController.navigationBar.hidden = YES;
    }
    // 添加按钮事件
    [self setupBtnEvent];
    
    // 隐藏状态栏
//    _sbPreStatus = [UIApplication sharedApplication].statusBarHidden;
//    [[UIApplication sharedApplication] setStatusBarHidden:YES];
}

- (void)recoverView {
    
    // 状态栏
//    [[UIApplication sharedApplication] setStatusBarHidden:_sbPreStatus];
    
    // 导航栏
    if (self.navigationController.navigationBar) {
        self.navigationController.navigationBar.hidden = _barPreStatus;
    }
}

- (void)setupBtnEvent {
    [self.barLeftBtn addTarget:self action:@selector(clickLeftBtn:) forControlEvents:UIControlEventTouchUpInside];
    [self.barRightBtn addTarget:self action:@selector(clickRightBtn:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)clickLeftBtn:(UIButton *)btn {
    if (self.navigationController) {
        [self.navigationController popViewControllerAnimated:true];
    }
}

- (void)clickRightBtn:(UIButton *)btn {
    NSLog(@"clicking right button...");
//    if (_scanTimer.isValid) {
//        [self stopScanAnimation];
//    } else {
//        [self startScanAnimation];
//    }
    BFScanEditVC *editVC = [[BFScanEditVC alloc] init];
    [self.navigationController pushViewController:editVC animated:YES];
}

#pragma 摄像头
// 判断摄像头使用权限
- (BOOL)checkCameraPromission {
    NSString *mediaType = AVMediaTypeVideo; // 读取媒体类型
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:mediaType]; // 读取设备授权状态
    if (authStatus == AVAuthorizationStatusRestricted || authStatus == AVAuthorizationStatusDenied) {
        NSString *errMsg = @"扫书功能需要访问您的相机\n请启用相机-设置/隐私/相机";
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"温馨提示" message:errMsg delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
        [alertView show];
        
        return false;
    }
    
    return true;
}

// 设置扫描界面
- (void)configureScanCamera {
    
    [self startScanAnimation];
    [self startReading];
}

// 开始扫描
- (BOOL)startReading {
    _startReading = YES;
    
    NSError *err;
    AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&err];
    
    if (!input) {
        NSLog(@"error: %@", [err localizedDescription]);
        return false;
    }
    
    _captureSession = [[AVCaptureSession alloc] init];
    [_captureSession addInput:input];
    
    AVCaptureMetadataOutput *output = [[AVCaptureMetadataOutput alloc] init];
    [_captureSession addOutput:output];
    
    //
    dispatch_queue_t captureQueue = dispatch_queue_create("CaptureQueue", NULL);
    [output setMetadataObjectsDelegate:self queue:captureQueue];
    // 设置扫描类型: 条形码
    [output setMetadataObjectTypes:[NSArray arrayWithObjects:
                                    AVMetadataObjectTypeEAN13Code,
                                    AVMetadataObjectTypeEAN8Code,
                                    AVMetadataObjectTypeCode128Code,
                                    AVMetadataObjectTypeQRCode, nil]];
    // 二维码
    //    [output setMetadataObjectTypes:[NSArray arrayWithObject:AVMetadataObjectTypeQRCode]];
    
    _captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
    [_captureVideoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    [_captureVideoPreviewLayer setFrame:self.view.layer.bounds];
    //    [self.view.layer addSublayer:_captureVideoPreviewLayer];
    [self.view.layer insertSublayer:_captureVideoPreviewLayer atIndex:0];
    
    [_captureSession startRunning];
    self.showPreparingView.hidden = YES;
    
    return true;
}
// 停止扫描
- (void)stopReading {
    [_captureSession stopRunning];
    _captureSession = nil;
    [_captureVideoPreviewLayer removeFromSuperlayer];
}

- (void)startScanAnimation {
    
    if (!_scanTimer) {
        if (_changeValue == 0 ) { _changeValue = kScanLineSpeed; }
        _borderDistance = kBorderDistance;
        _changeRangeH = self.scanFrame.bounds.size.height - _borderDistance - kScanLineSpeed;
        
        _scanTimer = [NSTimer scheduledTimerWithTimeInterval:0.02 target:self selector:@selector(scanAnimation) userInfo:nil repeats:YES];
    }
    
    [_scanTimer fire];
}

- (void)scanAnimation {
    
    float nextY = self.scanLineToTopConstraint.constant + _changeValue;
    // 改变扫描线的位置
    if (nextY <= _borderDistance || nextY >= _changeRangeH) {
        _changeValue = -_changeValue;
    }
    self.scanLineToTopConstraint.constant += _changeValue;
}

- (void)stopScanAnimation {
    if (_scanTimer) {
        [_scanTimer invalidate];
        _scanTimer = nil;
    }
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    if (!_startReading) { return; }
    
//    [self stopReading];
    [_captureSession stopRunning];
    [self stopScanAnimation];
    
    if (metadataObjects != nil && [metadataObjects count] > 0) {
        AVMetadataMachineReadableCodeObject *obj = [metadataObjects objectAtIndex:0];
        NSLog(@"scan result: %@", obj);
        
#warning  do what you want to do about scan result...
    }
}

@end
