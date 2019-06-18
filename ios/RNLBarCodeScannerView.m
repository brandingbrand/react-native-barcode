#import "RNLBarCodeModule.h"
#import "RNLBarCodeDecoder.h"
#import "RNLBarCodeUtils.h"
#import "RNLBarCodeScannerView.h"
#import "RNLBarCodeScannerViewAVImplementation.h"
#import "RNLBarCodeScannerViewZBarImplementation.h"

#import <React/RCTConvert.h>
#import <React/RCTUtils.h>
#import <ZBarSDK/ZBarSDK.h>

@interface RNLBarCodeScannerView ()<ZBarReaderViewDelegate>

@property (nullable, nonatomic, strong) NSObject<RNLBarCodeScannerViewImplementation> *viewImplementation;

@end

@implementation RNLBarCodeScannerView

@synthesize manager = _manager;
@synthesize decoderID = _decoderID;
@synthesize enable = _enable;
@synthesize formats = _formats;
@synthesize torch = _torch;
@synthesize onResult = _onResult;
@synthesize onError = _onError;
@synthesize viewImplementation = _viewImplementation;

- (void)dealloc
{
    [self.viewImplementation cleanUp];
}

- (void)didSetProps:(NSArray<NSString *> *)changedProps
{
    if (self.viewImplementation == nil) {
        if ([_decoderID isEqualToNumber:@4] || [_decoderID isEqualToNumber:@0]) {
            self.viewImplementation = [RNLBarCodeScannerViewAVImplementation new];
        } else if ([_decoderID isEqualToNumber:@2]) {
            self.viewImplementation = [RNLBarCodeScannerViewZBarImplementation new];
        } else {
            [self errorCallbackWithCode:RNLBarCodeInvokeFailedError
                             andMessage:@"Device doesn't support this decoder"];
            return;
        }
    }
    [self.viewImplementation onSetProps:changedProps parent:self];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self.viewImplementation layoutInParent:self];    
}

- (void)errorCallbackWithCode:(NSInteger)code andMessage:(NSString *)message
{
    if (_onError) {
        _onError(@{
                   @"code": [NSNumber numberWithInteger:code],
                   @"message": message,
                   });
    }
}

@end
