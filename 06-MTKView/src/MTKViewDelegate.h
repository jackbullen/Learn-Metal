#import "Renderer.h"
#import "MetalKitView.h"
#import <AppKit/AppKit.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>

@interface MTKViewDelegate : NSObject <MTKViewDelegate, KeyEventsDelegate>
@property(nonatomic, strong) Renderer *renderer;
- (instancetype)initWithDevice:(id<MTLDevice>)device;
@end