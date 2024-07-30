#import "AppDelegate.h"

@implementation AppDelegate

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
    [_pView setClearColor:MTLClearColorMake(1.0, 0.0, 0.0, 1.0)];
    [_pView setDepthStencilPixelFormat:MTLPixelFormatDepth16Unorm];
    [_pView setClearDepth:1.0f];

    _pViewDelegate = [[MTKViewDelegate alloc] initWithDevice:_pDevice];
    [_pView setDelegate:_pViewDelegate];

    [_pWindow setContentView:_pView];
    [_pWindow setTitle:@"06 - MTKView"];
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

@end 