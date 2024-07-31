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

- (void)mouseDown:(NSEvent *)event {
  NSPoint loc = [self convertPoint:[event locationInWindow] fromView:nil];
  [_keyEventsDelegate mouseDownEvent:&loc];
}

- (void)mouseUp:(NSEvent *)event {
  NSPoint loc = [self convertPoint:[event locationInWindow] fromView:nil];
  [_keyEventsDelegate mouseUpEvent:&loc];
}

- (void)mouseDragged:(NSEvent *)event {
  NSPoint loc = [self convertPoint:[event locationInWindow] fromView:nil];
  [_keyEventsDelegate mouseDraggedEvent:&loc];
}

@end