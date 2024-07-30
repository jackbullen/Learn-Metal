#import "MetalKitView.h"

@implementation MetalKitView

- (BOOL)acceptsFirstResponder {
  return YES;
}

- (void)keyDown:(NSEvent *)event {
  [super keyDown:event];
  NSLog(@"Key Down: %d", (int)event.keyCode);
  [self.keyEventsDelegate keyDownEvent:event];
}

- (void)keyUp:(NSEvent *)event {
  [super keyUp:event];
  NSLog(@"Key Up: %d", (int)event.keyCode);
  [self.keyEventsDelegate keyUpEvent:event];
}

@end