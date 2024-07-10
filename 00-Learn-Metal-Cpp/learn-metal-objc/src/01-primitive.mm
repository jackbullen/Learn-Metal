#import <Metal/Metal.h>
#import <AppKit/AppKit.h>
#import <MetalKit/MetalKit.h>

@interface Renderer: NSObject
- (instancetype)initWithDevice:(id<MTLDevice>)device;
- (void)buildShaders;
- (void)buildBuffers;
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
    [_pWindow setTitle:@"01 - Primitive"];
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
    id<MTLRenderPipelineState> _pPSO;
    id<MTLBuffer> _pVertexPositionsBuffer;
    id<MTLBuffer> _pVertexColorsBuffer;
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
        [self buildShaders];
        [self buildBuffers];
    }
    return self;
}

- (void)dealloc 
{
    _pVertexPositionsBuffer = nil;
    _pVertexColorsBuffer = nil;
    [super dealloc];
}

-(void)buildShaders
{
    NSString* shaderSrc = @"\
        #include <metal_stdlib> \n\
        using namespace metal; \n\
        struct v2f \n\
        { \n\
            float4 position [[position]]; \n\
            half3 color; \n\
        }; \n\
        v2f vertex vertexMain(device const float3* positions [[buffer(0)]], \n\
                              device const float3* colors [[buffer(1)]], \n\
                              uint vertexId [[vertex_id]]) \n\
        { \n\
            v2f o; \n\
            o.position = float4(positions[vertexId], 1.0); \n\
            o.color = half3(colors[vertexId]); \n\
            return o; \n\
        } \n\
        half4 fragment fragmentMain(v2f in [[stage_in]]) \n\
        { \n\
            return half4(in.color, 1.0); \n\
        } \n\
    ";

    NSError* error = nil;
    id<MTLLibrary> pLibrary = [_pDevice newLibraryWithSource:shaderSrc options:nil error:&error];
    if (!pLibrary)
    {
        NSLog(@"Could not create shader library: %@", error.localizedDescription);
        return;
    }

    id<MTLFunction> pVertexFn = [pLibrary newFunctionWithName:@"vertexMain"];
    if (!pVertexFn)
    {
        NSLog(@"Failed to load vertex function");
        return;
    }

    id<MTLFunction> pFragFn = [pLibrary newFunctionWithName:@"fragmentMain"];
    if (!pFragFn)
    {
        NSLog(@"Failed to load fragment function");
        return;
    }

    MTLRenderPipelineDescriptor* pDesc = [[MTLRenderPipelineDescriptor alloc] init];
    pDesc.vertexFunction = pVertexFn;
    pDesc.fragmentFunction = pFragFn;
    pDesc.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm_sRGB;

    _pPSO = [_pDevice newRenderPipelineStateWithDescriptor:pDesc error:&error];
    if (!_pPSO) 
    {
        NSLog(@"Failed to create render pipeline state: %@", error.localizedDescription);
        return;
    }
}

- (void)buildBuffers
{
    const size_t NumVertices = 3;

    simd::float3 positions[NumVertices] =
    {
        { -0.8f,  0.8f, 0.0f },
        {  0.0f, -0.8f, 0.0f },
        { +0.8f,  0.8f, 0.0f }
    };

    simd::float3 colors[NumVertices] =
    {
        {  1.0, 0.3f, 0.2f },
        {  0.8f, 1.0, 0.0f },
        {  0.8f, 0.0f, 1.0 }
    };

    const size_t positionsDataSize = sizeof(positions);
    const size_t colorsDataSize = sizeof(colors);

    _pVertexPositionsBuffer = [_pDevice newBufferWithBytes:positions length:positionsDataSize options:MTLResourceStorageModeManaged];
    [_pVertexPositionsBuffer didModifyRange:NSMakeRange(0, _pVertexPositionsBuffer.length)];

    _pVertexColorsBuffer = [_pDevice newBufferWithBytes:colors length:colorsDataSize options:MTLResourceStorageModeManaged];
    [_pVertexColorsBuffer didModifyRange:NSMakeRange(0, _pVertexColorsBuffer.length)];
}

- (void)draw:(MTKView *)pView
{
    @autoreleasepool
    {
        id<MTLCommandBuffer> pCmd = [_pCommandQueue commandBuffer];
        MTLRenderPassDescriptor* pRpd = pView.currentRenderPassDescriptor;
        id<MTLRenderCommandEncoder> pEnc = [pCmd renderCommandEncoderWithDescriptor:pRpd];

        [pEnc setRenderPipelineState:_pPSO];

        [pEnc setVertexBuffer:_pVertexPositionsBuffer offset:0 atIndex:0];
        [pEnc setVertexBuffer:_pVertexColorsBuffer offset:0 atIndex:1];

        [pEnc drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:3];

        [pEnc endEncoding];
        [pCmd presentDrawable:pView.currentDrawable];
        [pCmd commit];
    }
}

@end