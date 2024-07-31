#import "MTKViewDelegate.h"

@implementation MTKViewDelegate

- (instancetype)initWithDevice:(id<MTLDevice>)device {
  self = [super init];
  if (self) {
    _renderer = [[Renderer alloc] initWithDevice:device];
  }
  return self;
}

- (void)dealloc {
  [_renderer release];
  [super dealloc];
}

- (void)keyDownEvent:(NSEvent *)event {
  [_renderer keyDownEvent:event];
}

- (void)keyUpEvent:(NSEvent *)event {
  [_renderer keyUpEvent:event];
}

- (void)drawInMTKView:(MTKView *)view {
  [self.renderer draw:view];
}

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {
}

@end