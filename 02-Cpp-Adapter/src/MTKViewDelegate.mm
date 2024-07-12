#import "MTKViewDelegate.h"
#import "AppAdapter.h"

@implementation MTKViewDelegate
{
    id<MTLDevice> _pDevice;
    AppAdapter *_pAppAdapter;
}

- (instancetype)initWithDevice:(id<MTLDevice>)device
{
    _pDevice = device;
    _pAppAdapter = [AppAdapter alloc];
    return self;
}

- (void)drawInMTKView:(MTKView *)view 
{
    [_pAppAdapter draw:view device:_pDevice];
}

-(void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {}

@end