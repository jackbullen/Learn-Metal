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
    _pAppAdapter = [[AppAdapter alloc] initWithDevice:_pDevice];
    return self;
}

- (void)dealloc 
{
    [_pAppAdapter release];
    [_pDevice release];
    [super dealloc];
}

- (void)drawInMTKView:(MTKView *)view 
{
    [_pAppAdapter draw:view];
}

-(void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {}

@end