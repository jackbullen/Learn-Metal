#import "AppAdapter.h"

@implementation AppAdapter

- (void)draw:(MTKView*)pView device:(id<MTLDevice>)device;
{
    _pRenderer = new Renderer((__bridge MTK::View *)pView, (__bridge MTL::Device *)device);
    _pRenderer->draw();
}

- (void)dealloc 
{
    delete _pRenderer;
    [super dealloc];
}

@end