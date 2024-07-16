#import "Renderer.h"

@interface Renderer()
{
    id<MTLDevice> _pDevice;
    id<MTLCommandQueue> _pCommandQueue;
}
@end

@implementation Renderer

- (instancetype)initWithDevice:(id<MTLDevice>)device
{
    self = [super init];
    if (self)
    {
        _pDevice = device;
        _pCommandQueue = [_pDevice newCommandQueue];
    }
    return self;
}

- (void)dealloc 
{
    [super dealloc];
}

- (void)draw:(MTKView *)pView
{
    @autoreleasepool
    {
        id<MTLCommandBuffer> pCmd = [_pCommandQueue commandBuffer];
        MTLRenderPassDescriptor* pRpd = pView.currentRenderPassDescriptor;
        id<MTLRenderCommandEncoder> pEnc = [pCmd renderCommandEncoderWithDescriptor:pRpd];
        [pEnc endEncoding];
        [pCmd presentDrawable:pView.currentDrawable];
        [pCmd commit];
    }
}

@end