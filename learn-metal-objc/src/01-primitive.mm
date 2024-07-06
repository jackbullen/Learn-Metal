#import <Metal/Metal.h>
#import <AppKit/AppKit.h>
#import <MetalKit/MetalKit.h>

@interface Renderer: NSObject
- (instancetype)initWithDevice:(id<MTLDevice>)device;
- (void)draw:(MTKView *)view;
@end

@interface MyMTKViewDelegate : NSObject<MTKViewDelegate>
@property (nonatomic, strong) Renderer *renderer;
- (instancetype)initWithDevice:(id<MTLDevice>)device;
@end

@interface MyAppDelegate : NSObject<NSApplicationDelegate>
@property (nonatomic, strong) NSWindow* pWindow;
@property (nonatomic, strong) MTKView* pView;
@property (nonatomic, strong) id<MTLDevice> pDevice;
@property (nonatomic, strong) MyMTKViewDelegate* pViewDelegate;
- (NSMenu *)createMenuBar;
@end

int main(int argc, const char *argv[])
{
    @autoreleasepool 
    {
        MyAppDelegate *del = [[MyAppDelegate alloc] init];

        NSApplication *sharedApplication = [NSApplication sharedApplication];
        [sharedApplication setDelegate:del];
        [sharedApplication run];

        return 0;
    }
}

@implementation MyAppDelegate

- (void)dealloc
{
    [_pWindow release];
    [_pView release];
    [_pDevice release];
    [_pViewDelegate release];
    [super dealloc];
}

- (NSMenu *)createMenuBar 
{
    NSMenu *pMainMenu = [[NSMenu alloc] init];

    // App Menu
    NSMenuItem *pAppMenuItem = [[NSMenuItem alloc] initWithTitle:@"Appname" action:nil keyEquivalent:@""];
    NSMenu *pAppMenu = [[NSMenu alloc] initWithTitle:@"Appname"];
    NSRunningApplication *currentApp = [NSRunningApplication currentApplication];
    NSString *appName = [currentApp localizedName];
    NSString *quitItemName = [@"Quit " stringByAppendingString:appName];
    NSMenuItem *pAppQuitItem = [[NSMenuItem alloc] initWithTitle:quitItemName action:@selector(appQuit:) keyEquivalent:@"q"];
    [pAppQuitItem setTarget:self];
    [pAppMenu addItem:pAppQuitItem];
    [pAppMenuItem setSubmenu:pAppMenu];
    [pMainMenu addItem:pAppMenuItem];
    [pAppQuitItem release];
    [pAppMenu release];
    [pAppMenuItem release];

    // Window Menu
    NSMenuItem *pWindowMenuItem = [[NSMenuItem alloc] initWithTitle:@"Window" action:nil keyEquivalent:@""];
    NSMenu *pWindowMenu = [[NSMenu alloc] initWithTitle:@"Window"];
    NSMenuItem *pCloseWindowItem = [[NSMenuItem alloc] initWithTitle:@"Close Window" action:@selector(windowClose:) keyEquivalent:@"w"];
    [pCloseWindowItem setTarget:self];
    [pWindowMenu addItem:pCloseWindowItem];
    [pWindowMenuItem setSubmenu:pWindowMenu];
    [pMainMenu addItem:pWindowMenuItem];
    [pCloseWindowItem release];
    [pWindowMenu release];
    [pWindowMenuItem release];

    return [pMainMenu autorelease];
}

- (void)applicationWillFinishLaunching:(NSNotification *)notification 
{
    NSMenu *pMenu = [self createMenuBar];
    [NSApp setMainMenu:pMenu];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification 
{
    CGRect frame = CGRectMake(100.0, 100.0, 512.0, 512.0);

    _pWindow = [[NSWindow alloc] initWithContentRect:frame
                                            styleMask:NSWindowStyleMaskClosable | NSWindowStyleMaskTitled
                                              backing:NSBackingStoreBuffered
                                                defer:NO];

    _pDevice = MTLCreateSystemDefaultDevice();

    _pView = [[MTKView alloc] initWithFrame:frame device:_pDevice];
    [_pView setColorPixelFormat:MTLPixelFormatBGRA8Unorm_sRGB];
    [_pView setClearColor:MTLClearColorMake(0.0, 0.0, 1.0, 1.0)];
    [_pView setDepthStencilPixelFormat:MTLPixelFormatDepth16Unorm];
    [_pView setClearDepth:1.0f];

    _pViewDelegate = [[MyMTKViewDelegate alloc] initWithDevice:_pDevice];
    [_pView setDelegate:_pViewDelegate];

    [_pWindow setContentView:_pView];
    [_pWindow setTitle:@"00 - Window"];
    [_pWindow makeKeyAndOrderFront:nil];

    [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
    [NSApp activateIgnoringOtherApps: YES];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender 
{
    return YES;
}

- (void)appQuit:(id)sender 
{
    [NSApp terminate:sender];
}

- (void)windowClose:(id)sender 
{
    [[NSApp windows][0] close];
}

@end // MyAppDelegate

@implementation MyMTKViewDelegate

- (instancetype)initWithDevice:(id<MTLDevice>)device
{
    self = [super init];
    if (self) 
    {
        _renderer = [[Renderer alloc] initWithDevice:device];
    }
    return self;
}

- (void)dealloc 
{
    [_renderer release];
    [super dealloc];
}

- (void)drawInMTKView:(MTKView *)view 
{
    [self.renderer draw:view];
}

-(void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {}

@end // MyMTKViewDelegate

@interface Renderer()
{
    id<MTLDevice> _pDevice;
    id<MTLCommandQueue> _pCommandQueue;
}
@end

@implementation Renderer

- (instancetype)initWithDevice:(id<MTLDevice>)device
{
    self = [super init];
    if (self)
    {
        _pDevice = device;
        _pCommandQueue = [_pDevice newCommandQueue];
    }
    return self;
}

- (void)dealloc 
{
    [super dealloc];
}

- (void)draw:(MTKView *)pView
{
    @autoreleasepool
    {
        id<MTLCommandBuffer> pCmd = [_pCommandQueue commandBuffer];
        MTLRenderPassDescriptor* pRpd = pView.currentRenderPassDescriptor;
        id<MTLRenderCommandEncoder> pEnc = [pCmd renderCommandEncoderWithDescriptor:pRpd];
        [pEnc endEncoding];
        [pCmd presentDrawable:pView.currentDrawable];
        [pCmd commit];
    }
}

@end