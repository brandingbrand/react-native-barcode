#import "RNLBarCodeScannerViewManager.h"
#import "RNLBarCodeScannerView.h"
#import "RNLBarCodeUtils.h"

#import <React/RCTUtils.h>

@interface RNLBarCodeScannerViewManager ()

@end

@implementation RNLBarCodeScannerViewManager

@synthesize methodQueue = _methodQueue;

RCT_EXPORT_MODULE(RNLBarCodeScannerView)

+ (BOOL)requiresMainQueueSetup
{
    return NO;
}

RCT_EXPORT_VIEW_PROPERTY(enable, BOOL)

RCT_EXPORT_VIEW_PROPERTY(decoderID, NSNumber)

RCT_EXPORT_VIEW_PROPERTY(formats, NSArray)

RCT_EXPORT_VIEW_PROPERTY(torch, NSNumber)

RCT_EXPORT_VIEW_PROPERTY(onResult, RCTDirectEventBlock)

RCT_EXPORT_VIEW_PROPERTY(onError, RCTDirectEventBlock)

- (UIView *)view
{
    RNLBarCodeScannerView *view = [RNLBarCodeScannerView new];
    // weak property
    view.manager = self;
    return view;
}

@end
