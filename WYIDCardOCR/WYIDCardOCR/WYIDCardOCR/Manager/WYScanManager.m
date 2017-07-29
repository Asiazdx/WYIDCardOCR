//
//  WYScanManager.m
//  WYIDCardOCR
//
//  Created by 汪年成 on 17/7/6.
//  Copyright © 2017年 之静之初. All rights reserved.
//

#import "WYScanManager.h"

@interface WYScanManager ()

@end

@implementation WYScanManager


- (BOOL)configBankScanManager {
    self.scanType = BankScanType;
    return [self configSession];
}

- (BOOL)configIDScanManager {
    [self configIDScan];
    self.verify = YES;
    self.scanType = IDScanFrontType;
    return [self configSession];
}

- (BOOL)configIDDownScanManager {
    [self configIDScan];
    self.verify = YES;
    self.scanType = IDScanDownType;
    return [self configSession];
}


- (BOOL)configSession {
    [self resetConfig];
    dispatch_queue_t captureQueue = dispatch_queue_create("www.captureQue.com", NULL);
    self.captureSession.sessionPreset = AVCaptureSessionPreset1280x720;
    
    if (![self configInPutAtQue:captureQueue] || ![self configOutPutAtQue:captureQueue]) {
        return NO;
    }
    [self configConnection];
    
    AVCaptureDevice *device = [self activeCamera];
    
    if(YES == [device lockForConfiguration:NULL]) {
        
        if([device respondsToSelector:@selector(setSmoothAutoFocusEnabled:)] && [device isSmoothAutoFocusSupported]) {
            [device setSmoothAutoFocusEnabled:YES];
        }
        AVCaptureFocusMode currentMode = [device focusMode];
        if(currentMode == AVCaptureFocusModeLocked) {
            
            currentMode = AVCaptureFocusModeAutoFocus;
        }
        if([device isFocusModeSupported:currentMode]) {
            
            [device setFocusMode:currentMode];
        }
        [device unlockForConfiguration];
    }
    [self.captureSession commitConfiguration];
    
    [self.receiveSubject subscribeNext:^(id x) {
        CVImageBufferRef imageBuffer = (__bridge CVImageBufferRef)(x);
        [self doRec:imageBuffer];
    }];
    [self.bankScanSuccess subscribeNext:^(id x) {
        
    }];
    [self.idCardScanSuccess subscribeNext:^(id x) {
        
    }];
    [self.scanError subscribeNext:^(id x) {
        
    }];
    return YES;
}

- (void)doRec:(CVImageBufferRef)imageBuffer {
    @synchronized(self) {
        self.isInProcessing = YES;
        if (self.isHasResult) {
            return;
        }
        CVBufferRetain(imageBuffer);
        if(CVPixelBufferLockBaseAddress(imageBuffer, 0) == kCVReturnSuccess) {
            switch (self.scanType) {
                case BankScanType: {
                    [self parseBankImageBuffer:imageBuffer];
                }
                    break;
                case IDScanFrontType: {
                    [self parseIDFrontCardImageBuffer:imageBuffer];
                }
                    break;
                case IDScanDownType: {
                    [self parseIDDownCardImageBuffer:imageBuffer];
                }
                default:
                    break;
            }
        }
        CVBufferRelease(imageBuffer);
    }
}


@end
