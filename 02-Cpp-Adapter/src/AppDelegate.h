#import <AppKit/AppKit.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import "MTKViewDelegate.h"

@interface AppDelegate : NSObject<NSApplicationDelegate>
@property (nonatomic, strong) NSWindow* pWindow;
@property (nonatomic, strong) MTKView* pView;
@property (nonatomic, strong) id<MTLDevice> pDevice;
@property (nonatomic, strong) MTKViewDelegate* pViewDelegate;
@end