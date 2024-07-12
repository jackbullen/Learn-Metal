#import "QuartzCore/CAMetalLayer.h"
#import "Metal/MTLDevice.h"
#import "MetalKit/MetalKit.h"
#import "Renderer.hpp"


@interface AppAdapter : NSObject
{
    Renderer *_pRenderer;
}

- (instancetype)initWithDevice:(id<MTLDevice>)device;
- (void)draw:(MTKView*)pView;

@end