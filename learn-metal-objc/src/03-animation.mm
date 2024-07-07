#import <Metal/Metal.h>
#import <AppKit/AppKit.h>
#import <MetalKit/MetalKit.h>

static const size_t kMaxFramesInFlight = 3;

struct FrameData
{
    float angle;
};

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
    [_pWindow setTitle:@"03 - Animation"];
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
    id<MTLLibrary> _pShaderLibrary;
    id<MTLRenderPipelineState> _pPSO;
    id<MTLBuffer> _pArgBuffer;
    id<MTLBuffer> _pVertexPositionsBuffer;
    id<MTLBuffer> _pVertexColorsBuffer;
    id<MTLBuffer> _pFrameData[kMaxFramesInFlight];
    int _frame;
    float _angle;
    dispatch_semaphore_t _semaphore;
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

        _semaphore = dispatch_semaphore_create(kMaxFramesInFlight);
    }
    return self;
}

- (void)dealloc 
{
    _pVertexPositionsBuffer = nil;
    _pVertexColorsBuffer = nil;
    for (int i = 0; i < kMaxFramesInFlight; i++)
    {
        _pFrameData[i] = nil;
    }
    _pShaderLibrary = nil;
    _pArgBuffer = nil;
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
        struct VertexData \n\
        { \n\
            device float3* positions [[id(0)]]; \n\
            device float3* colors [[id(1)]]; \n\
        }; \n\
        struct FrameData \n\
        { \n\
            float angle; \n\
        }; \n\
        v2f vertex vertexMain(device const VertexData* vertexData [[buffer(0)]], \n\
                              device const FrameData* frameData [[buffer(1)]], \n\
                              uint vertexId [[vertex_id]]) \n\
        { \n\
            v2f o; \n\
            float a = frameData->angle; \n\
            float3x3 Rz = float3x3( sin(a), cos(a), 0.0, cos(a), -sin(a), 0.0, 0.0, 0.0, 1.0 ); \n\
            o.position = float4(Rz * vertexData->positions[vertexId], 1.0); \n\
            o.color = half3(Rz * vertexData->colors[vertexId]); \n\
            return o; \n\
        } \n\
        half4 fragment fragmentMain(v2f in [[stage_in]]) \n\
        { \n\
            return half4(in.color, 1.0); \n\
        } \n\
    ";

    NSError* error = nil;
    _pShaderLibrary = [_pDevice newLibraryWithSource:shaderSrc options:nil error:&error];
    if (!_pShaderLibrary)
    {
        NSLog(@"Could not create shader library: %@", error.localizedDescription);
        return;
    }

    id<MTLFunction> pVertexFn = [_pShaderLibrary newFunctionWithName:@"vertexMain"];
    if (!pVertexFn)
    {
        NSLog(@"Failed to load vertex function");
        return;
    }

    id<MTLFunction> pFragFn = [_pShaderLibrary newFunctionWithName:@"fragmentMain"];
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

    id<MTLFunction> pVertexFn = [_pShaderLibrary newFunctionWithName:@"vertexMain"];
    id<MTLArgumentEncoder> pArgEncoder = [pVertexFn newArgumentEncoderWithBufferIndex:0];

    _pArgBuffer = [_pDevice newBufferWithLength:[pArgEncoder encodedLength] options:MTLResourceStorageModeManaged];

    [pArgEncoder setArgumentBuffer:_pArgBuffer offset:0];

    [pArgEncoder setBuffer:_pVertexPositionsBuffer offset:0 atIndex:0];
    [pArgEncoder setBuffer:_pVertexColorsBuffer offset:0 atIndex:1];

    [_pArgBuffer didModifyRange:NSMakeRange(0, _pArgBuffer.length)];

    pVertexFn = nil;
    pArgEncoder = nil;

    for (int i = 0; i < kMaxFramesInFlight; i++)
    {
        _pFrameData[i] = [_pDevice newBufferWithLength:sizeof(FrameData) options:MTLResourceStorageModeManaged];
    }
}

- (void)draw:(MTKView *)pView
{
    @autoreleasepool
    {
        // this could go later for a slight optimization.. i think?
        dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);

        _frame = (_frame + 1) % kMaxFramesInFlight;
        id<MTLBuffer> pFrameDataBuffer = _pFrameData[_frame];

        ((FrameData *)pFrameDataBuffer.contents)->angle = (_angle += 0.01f);
        [pFrameDataBuffer didModifyRange:NSMakeRange(0, pFrameDataBuffer.length)];

        id<MTLCommandBuffer> pCmd = [_pCommandQueue commandBuffer];

        [pCmd addCompletedHandler:^(id<MTLCommandBuffer> buffer) {
            dispatch_semaphore_signal(_semaphore);
        }];

        MTLRenderPassDescriptor* pRpd = pView.currentRenderPassDescriptor;
        id<MTLRenderCommandEncoder> pEnc = [pCmd renderCommandEncoderWithDescriptor:pRpd];

        [pEnc setRenderPipelineState:_pPSO];

        [pEnc setVertexBuffer:_pArgBuffer offset:0 atIndex:0];
        [pEnc useResource:_pVertexPositionsBuffer usage:MTLResourceUsageRead];
        [pEnc useResource:_pVertexColorsBuffer usage:MTLResourceUsageRead];

        [pEnc setVertexBuffer:pFrameDataBuffer offset:0 atIndex:1];

        [pEnc drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:3];

        [pEnc endEncoding];
        [pCmd presentDrawable:pView.currentDrawable];
        [pCmd commit];
    }
}

@end