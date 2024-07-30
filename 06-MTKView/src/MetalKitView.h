#import <MetalKit/MetalKit.h>

@protocol KeyEventsDelegate <NSObject>
- (void)keyDownEvent:(NSEvent *)event;
- (void)keyUpEvent:(NSEvent *)event;
@end

@interface MetalKitView : MTKView
@property(nonatomic, unsafe_unretained) id<KeyEventsDelegate> keyEventsDelegate;
@end