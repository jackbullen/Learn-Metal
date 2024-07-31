#import <MetalKit/MetalKit.h>

@protocol KeyEventsDelegate <NSObject>
- (void)keyDownEvent:(NSEvent *)event;
- (void)keyUpEvent:(NSEvent *)event;
- (void)mouseDownEvent:(NSPoint *)event;
- (void)mouseUpEvent:(NSPoint *)event;
- (void)mouseDraggedEvent:(NSPoint *)event;
@end

@interface MetalKitView : MTKView
@property(nonatomic, unsafe_unretained) id<KeyEventsDelegate> keyEventsDelegate;
@end