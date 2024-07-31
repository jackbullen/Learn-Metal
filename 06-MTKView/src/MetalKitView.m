#import "MetalKitView.h"

@implementation MetalKitView

- (BOOL)acceptsFirstResponder {
  return YES;
}

- (void)keyDown:(NSEvent *)event {
  [_keyEventsDelegate keyDownEvent:event];
}

- (void)keyUp:(NSEvent *)event {
  [_keyEventsDelegate keyUpEvent:event];
}

@end