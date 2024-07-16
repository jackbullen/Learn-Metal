#import <AppKit/AppKit.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import "Renderer.h"

@interface MTKViewDelegate : NSObject<MTKViewDelegate>
@property (nonatomic, strong) Renderer *renderer;
- (instancetype)initWithDevice:(id<MTLDevice>)device;
@end