//
//  RNLBarCodeScannerViewZBarImplementation.m
//  RNLBarCode
//
//  Created by Maksym Domin on 6/18/19.
//  Copyright © 2019 rnlibrary. All rights reserved.
//

#import "RNLBarCodeScannerViewZBarImplementation.h"
#import "RNLBarCodeScannerView.h"
#import "RNLBarCodeDecoder.h"
#import <ZBarSDK/ZBarSDK.h>

@interface RNLBarCodeScannerViewZBarImplementation()<ZBarReaderViewDelegate>

@property (nullable, nonatomic, strong) ZBarReaderView *readerView;
@property (nonatomic, assign) BOOL enable;
@property (nullable, nonatomic, weak) RNLBarCodeScannerView *parent;

@end


@implementation RNLBarCodeScannerViewZBarImplementation

@synthesize readerView = _readerView;
@synthesize enable = _enable;
@synthesize parent = parent;

- (void)cleanUp
{
    [self.readerView stop];
}

- (void)onSetProps:(NSArray<NSString *> *)changedProps parent:(RNLBarCodeScannerView *)parent
{
    if (self.readerView == nil) {
        self.parent = parent;
        ZBarImageScanner *scanner = [ZBarImageScanner new];
        scanner.enableCache = YES;
        [RNLBarCodeDecoderZBar setFormats:parent.formats forScanner:scanner];
        self.readerView = [[ZBarReaderView alloc] initWithImageScanner:scanner];
        [parent addSubview:self.readerView];
        self.readerView.readerDelegate = self;
    }
    if (self.enable != parent.enable) {
        if (parent.enable) {
            [self.readerView start];
        } else {
            [self.readerView stop];
        }
    }
    self.enable = parent.enable;
    self.readerView.torchMode = parent.torch.integerValue;
}

- (void)layoutInParent:(RNLBarCodeScannerView *)parent
{
    if (_readerView != nil) {
        _readerView.frame = CGRectMake(
                                       0,
                                       0,
                                       parent.frame.size.width,
                                       parent.frame.size.height);
    }
}

- (void) readerView: (ZBarReaderView*) view didReadSymbols: (ZBarSymbolSet*) syms fromImage: (UIImage*) img
{
    for(ZBarSymbol *sym in syms) {
        NSDictionary *result = @{@"format" : @(sym.type), @"content": sym.data};
        if (self.parent.onResult) {
            self.parent.onResult(result);
        }
        break;
    }
}

- (void) readerView: (ZBarReaderView*) readerView didStopWithError: (NSError*) error {
    if (error) {
        [self.parent errorCallbackWithCode:error.code andMessage:error.localizedDescription];
    }
}

@end
