#import "MTKViewDelegate.h"
#import "MetalKitView.h"
#import <AppKit/AppKit.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>
@property(nonatomic, strong) NSWindow *pWindow;
@property(nonatomic, strong) id<MTLDevice> pDevice;
@property(nonatomic, strong) MetalKitView *pView;
@property(nonatomic, strong) MTKViewDelegate *pViewDelegate;
@end