#import "QuartzCore/CAMetalLayer.h"
#import "Metal/MTLDevice.h"
#import "MetalKit/MetalKit.h"
#import "Renderer.hpp"


@interface AppAdapter : NSObject
{
    Renderer *_pRenderer;
}

- (void)draw:(MTKView*)pView device:(id<MTLDevice>)device;

@end