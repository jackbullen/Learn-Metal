#import <AppKit/AppKit.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>

@interface Renderer: NSObject
- (instancetype)initWithDevice:(id<MTLDevice>)device;
- (void)draw:(MTKView *)view;
@end