#import "MetalKitView.h"

@implementation MetalKitView

- (BOOL)acceptsFirstResponder {
  return YES;
}

- (void)keyDown:(NSEvent *)event {
  [super keyDown:event];
  [self.keyEventsDelegate keyDownEvent:event];
}

- (void)keyUp:(NSEvent *)event {
  [super keyUp:event];
  [self.keyEventsDelegate keyUpEvent:event];
}

@end