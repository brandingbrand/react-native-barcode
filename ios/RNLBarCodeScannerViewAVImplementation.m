//
//  RNLBarCodeScannerViewAVImplementation.m
//  RNLBarCode
//
//  Created by Maksym Domin on 6/18/19.
//  Copyright © 2019 rnlibrary. All rights reserved.
//

#import "RNLBarCodeModule.h"
#import "RNLBarCodeScannerViewAVImplementation.h"
#import "RNLBarCodeScannerView.h"
#import "RNLBarCodeDecoder.h"
#import "RNLBarCodeScannerViewManager.h"
#import <AVFoundation/AVFoundation.h>


@interface RNLBarCodeScannerViewAVImplementation()

@property (nonatomic, retain) AVCaptureDeviceInput *input;

@property (nonatomic, retain) AVCaptureVideoPreviewLayer *previewLayer;

@property (nonatomic, retain) RNLBarCodeDecoderAV *decoder;

@property (nonatomic, assign) BOOL initializeSuccess;

@end


@implementation RNLBarCodeScannerViewAVImplementation

@synthesize input = _input;
@synthesize previewLayer = _previewLayer;
@synthesize decoder = _decoder;
@synthesize initializeSuccess = _initializeSuccess;

static AVCaptureDevice *_device;
static AVCaptureSession *_session;

- (void)cleanUp
{
    [RNLBarCodeScannerViewAVImplementation.session removeInput:_input];
    [RNLBarCodeScannerViewAVImplementation.session removeOutput:_decoder.output];
    if (RNLBarCodeScannerViewAVImplementation.session.isRunning) {
        [RNLBarCodeScannerViewAVImplementation.session stopRunning];
    }
}

- (void)onSetProps:(NSArray<NSString *> *)changedProps parent:(RNLBarCodeScannerView *)parent
{
    dispatch_async(parent.manager.methodQueue, ^{
        [self refreshInParent:parent];
    });
}

- (void)layoutInParent:(RNLBarCodeScannerView *)parent
{
    if (_previewLayer != nil) {
        _previewLayer.frame = CGRectMake(
                                         -parent.layer.frame.origin.x,
                                         -parent.layer.frame.origin.y,
                                         _previewLayer.frame.size.width,
                                         _previewLayer.frame.size.height);
    }
}

- (void)refreshInParent:(RNLBarCodeScannerView *)parent
{
    if (!_initializeSuccess) {
        static BOOL hasCameraPermission;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            AVAuthorizationStatus permission = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
            if (AVAuthorizationStatusAuthorized == permission) {
                hasCameraPermission = YES;
            } else if (AVAuthorizationStatusNotDetermined == permission) {
                [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                    if (granted) {
                        hasCameraPermission = YES;
                        dispatch_async(parent.manager.methodQueue, ^{
                            [self refreshInParent:parent];
                        });
                    }
                }];
                return;
            }
        });
        if (!hasCameraPermission) {
            [parent errorCallbackWithCode:RNLBarCodeNoCameraPermission
                               andMessage:@"Don't authorize use camera"];
            return;
        }
        if (RNLBarCodeScannerViewAVImplementation.device == nil) {
            [parent errorCallbackWithCode:RNLBarCodeNoCameraDevice
                               andMessage:@"Device doesn't have available camera"];
            return;
        }
        if (_previewLayer == nil) {
            _previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:RNLBarCodeScannerViewAVImplementation.session];
            CGSize screenSize = RCTScreenSize();
            _previewLayer.frame = CGRectMake(0, 0, screenSize.width, screenSize.height);
            [_previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
        }
        if (_input == nil) {
            NSError *error;
            _input = [AVCaptureDeviceInput deviceInputWithDevice:RNLBarCodeScannerViewAVImplementation.device error:&error];
            if (_input == nil) {
                [parent errorCallbackWithCode:RNLBarCodeInvokeFailedError
                                   andMessage:[NSString stringWithFormat:@"Instance iOS AVCaptureDeviceInput failed, reason %@", error]];
                return;
            }
        }
        if ([RNLBarCodeScannerViewAVImplementation.session canAddInput:_input]) {
            [RNLBarCodeScannerViewAVImplementation.session addInput:_input];
        } else {
            [parent errorCallbackWithCode:RNLBarCodeInvokeFailedError
                               andMessage:@"IOS AVCaptureSession can't add AVCaptureDeviceInput"];
            return;
        }
        _initializeSuccess = YES;

        dispatch_async(dispatch_get_main_queue(), ^{
            [parent.layer insertSublayer:self->_previewLayer atIndex:0];
        });
        if (!RNLBarCodeScannerViewAVImplementation.session.isRunning) {
            [RNLBarCodeScannerViewAVImplementation.session startRunning];
        }
    }
    // view props update
    if ([parent.decoderID isEqualToNumber:@4] || [parent.decoderID isEqualToNumber:@0]) {
        // AVFoundation or Auto
        if (_decoder == nil) {
            _decoder = [RNLBarCodeDecoderAV new];
        }
    } else {
        [parent errorCallbackWithCode:RNLBarCodeInvokeFailedError
                           andMessage:@"Device doesn't support this decoder"];
        return;
    }
    if (parent.enable) {
        if (![RNLBarCodeScannerViewAVImplementation.session.outputs containsObject:_decoder.output]) {
            if ([RNLBarCodeScannerViewAVImplementation.session canAddOutput:_decoder.output]) {
                [RNLBarCodeScannerViewAVImplementation.session addOutput:_decoder.output];
            } else {
                [parent errorCallbackWithCode:RNLBarCodeInvokeFailedError
                                   andMessage:@"IOS AVCaptureSession can't add AVCaptureMetadataOutput"];
                return;
            }
        }
    } else {
        if ([RNLBarCodeScannerViewAVImplementation.session.outputs containsObject:_decoder.output]) {
            [RNLBarCodeScannerViewAVImplementation.session removeOutput:_decoder.output];
        }
    }
    if (parent.enable && [RNLBarCodeScannerViewAVImplementation.session.outputs containsObject:_decoder.output]) {
        [_decoder setFormats:parent.formats];
        __weak RNLBarCodeScannerView *weakParent = parent;
        [_decoder startDecodeWithQueue:parent.manager.methodQueue andResultCallback:^(NSDictionary * _Nonnull result) {
            if (weakParent.onResult) weakParent.onResult(result);
        }];
    }
    BOOL isLocked = NO;
    if (AVCaptureTorchModeOn == parent.torch.integerValue) {
        if (RNLBarCodeScannerViewAVImplementation.device.torchMode != AVCaptureTorchModeOn &&
            RNLBarCodeScannerViewAVImplementation.device.torchAvailable &&
            [RNLBarCodeScannerViewAVImplementation.device isTorchModeSupported:AVCaptureTorchModeOn]) {
            if (!isLocked) {
                isLocked = [RNLBarCodeScannerViewAVImplementation.device lockForConfiguration:nil];
            }
            if (isLocked) {
                RNLBarCodeScannerViewAVImplementation.device.torchMode = AVCaptureTorchModeOn;
            }
        }
    } else if (AVCaptureTorchModeAuto == parent.torch.integerValue) {
        if (RNLBarCodeScannerViewAVImplementation.device.torchMode != AVCaptureTorchModeAuto &&
            RNLBarCodeScannerViewAVImplementation.device.torchAvailable &&
            [RNLBarCodeScannerViewAVImplementation.device isTorchModeSupported:AVCaptureTorchModeAuto]) {
            if (!isLocked) {
                isLocked = [RNLBarCodeScannerViewAVImplementation.device lockForConfiguration:nil];
            }
            if (isLocked) {
                RNLBarCodeScannerViewAVImplementation.device.torchMode = AVCaptureTorchModeAuto;
            }
        }
    } else if (AVCaptureTorchModeOff == parent.torch.integerValue) {
        if (RNLBarCodeScannerViewAVImplementation.device.torchMode != AVCaptureTorchModeOff &&
            RNLBarCodeScannerViewAVImplementation.device.torchAvailable &&
            [RNLBarCodeScannerViewAVImplementation.device isTorchModeSupported:AVCaptureTorchModeOff]) {
            if (!isLocked) {
                isLocked = [RNLBarCodeScannerViewAVImplementation.device lockForConfiguration:nil];
            }
            if (isLocked) {
                RNLBarCodeScannerViewAVImplementation.device.torchMode = AVCaptureTorchModeOff;
            }
        }
    }
    if (isLocked) {
        [RNLBarCodeScannerViewAVImplementation.device unlockForConfiguration];
    }
}

+ (AVCaptureDevice *)device
{
    if (_device == nil) {
        NSArray<AVCaptureDevice *> *devices;
        if (@available(iOS 10.0, *)) {
            AVCaptureDeviceDiscoverySession *session = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInWideAngleCamera] mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionUnspecified];
            devices = session.devices;
        } else {
            devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
        }
        if (devices.count > 0) {
            _device = [devices firstObject];
            for (int i = 1; i < [devices count]; i++) {
                if ([devices objectAtIndex:i].position == AVCaptureDevicePositionBack) {
                    _device = [devices objectAtIndex:i];
                }
            }
        }
    }
    return _device;
}

+ (AVCaptureSession *)session
{
    if (_session == nil) {
        _session = [AVCaptureSession new];
    }
    return _session;
}

@end
