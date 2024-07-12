#import "AppAdapter.h"

@implementation AppAdapter

- (instancetype)initWithDevice:(id<MTLDevice>)device
{
    _pRenderer = new Renderer((__bridge MTL::Device *)device);
    return self;
}

- (void)dealloc 
{
    delete _pRenderer;
    [super dealloc];
}

- (void)draw:(MTKView*)view;
{
    _pRenderer->draw((__bridge MTK::View *)view);
}

@end