#import <AppKit/AppKit.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import "Renderer.hpp"
#import "AppAdapter.h"

@interface MTKViewDelegate : NSObject<MTKViewDelegate>
- (instancetype)initWithDevice:(id<MTLDevice>)device;
@end