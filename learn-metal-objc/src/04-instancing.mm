#import <Metal/Metal.h>
#import <AppKit/AppKit.h>
#import <MetalKit/MetalKit.h>
#import <simd/simd.h>

#define kNumInstances 32
static const size_t kMaxFramesInFlight = 3;

struct InstanceData
{
    simd::float4x4 instanceTransform;
    simd::float4 instanceColor;
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
    [_pWindow setTitle:@"04 - Instancing"];
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
    id<MTLBuffer> _pVertexDataBuffer;
    id<MTLBuffer> _pInstanceDataBuffer[kMaxFramesInFlight];
    id<MTLBuffer> _pIndexBuffer;
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
    _pDevice = nil;
    _pPSO = nil;
    _pCommandQueue = nil;
    _pVertexDataBuffer = nil;
    for (int i = 0; i < kMaxFramesInFlight; i++)
    {
        _pInstanceDataBuffer[i] = nil;
    }
    _pShaderLibrary = nil;
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
            half4 color; \n\
        }; \n\
        struct VertexData \n\
        { \n\
            float3 position; \n\
        }; \n\
        struct InstanceData \n\
        { \n\
            float4x4 instanceTransform; \n\
            float4 instanceColor; \n\
        }; \n\
        v2f vertex vertexMain(device const VertexData* vertexData [[buffer(0)]], \n\
                              device const InstanceData* instanceData [[buffer(1)]], \n\
                              uint vertexId [[vertex_id]], \n\
                              uint instanceId [[instance_id]]) \n\
        { \n\
            v2f o; \n\
            float4 pos = float4(vertexData[vertexId].position, 1.0); \n\
            o.position = instanceData[instanceId].instanceTransform * pos; \n\
            o.color = half4(half3(instanceData[instanceId].instanceColor.rgb), \n\
                                  instanceData[instanceId].instanceColor.w); \n\
            return o; \n\
        } \n\
        half4 fragment fragmentMain(v2f in [[stage_in]]) \n\
        { \n\
            return half4(in.color.xyz, 1.0); \n\
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
    const float s = 0.5f;

    simd::float3 vertices[] = {
        { -s, -s, +s },
        { +s, -s, +s },
        { +s, +s, +s },
        { -s, +s, +s }
    };

    uint16_t indices[] = {
        0, 1, 2,
        2, 3, 0,
    };

    const size_t verticesDataSize = sizeof(vertices);
    const size_t indicesDataSize = sizeof(indices);

    _pVertexDataBuffer = [_pDevice newBufferWithBytes:vertices length:verticesDataSize options:MTLResourceStorageModeManaged];
    [_pVertexDataBuffer didModifyRange:NSMakeRange(0, _pVertexDataBuffer.length)];

    _pIndexBuffer = [_pDevice newBufferWithBytes:indices length:indicesDataSize options:MTLResourceStorageModeManaged];
    [_pIndexBuffer didModifyRange:NSMakeRange(0, _pIndexBuffer.length)];

    const size_t instanceDataSize = kNumInstances * sizeof( InstanceData );
    for (int i = 0; i < kMaxFramesInFlight; i++)
    {
        _pInstanceDataBuffer[i] = [_pDevice newBufferWithLength:instanceDataSize options:MTLResourceStorageModeManaged];
    }
}

- (void)draw:(MTKView *)pView
{
    @autoreleasepool
    {
        // this could go later for a slight optimization.. i think?
        dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);

        _frame = (_frame + 1) % kMaxFramesInFlight;
        id<MTLBuffer> pInstanceDataBuffer = _pInstanceDataBuffer[_frame];

        id<MTLCommandBuffer> pCmd = [_pCommandQueue commandBuffer];

        [pCmd addCompletedHandler:^(id<MTLCommandBuffer> buffer) {
            dispatch_semaphore_signal(_semaphore);
        }];

        _angle += 0.01f;

        const float scl = 0.1f;

        InstanceData* pInstanceData = reinterpret_cast< InstanceData *>( pInstanceDataBuffer.contents );
        for ( size_t i = 0; i < kNumInstances; ++i )
        {
            float iDivNumInstances = i / (float)kNumInstances;
            float xoff = (iDivNumInstances * 2.0f - 1.0f) + (1.f/kNumInstances);
            float yoff = sin(( iDivNumInstances + _angle ) * 2.0f * M_PI);
            pInstanceData[i].instanceTransform = (simd::float4x4){ 
                (simd::float4){ scl * sinf(_angle), scl * cosf(_angle) ,      0.f     ,   0.f },
                (simd::float4){ scl * cosf(_angle), scl * -sinf(_angle),      0.f     ,   0.f },
                (simd::float4){        0.f        ,        0.f         ,      scl     ,   0.f },
                (simd::float4){        xoff       ,        yoff        ,      0.f     ,   1.f } };

            float r = iDivNumInstances;
            float g = 1.0f - r;
            float b = sinf(M_PI * 2.0f * iDivNumInstances);
            pInstanceData[i].instanceColor = (simd::float4){ r, g, b, 1.0f };
        }
        [pInstanceDataBuffer didModifyRange:NSMakeRange(0, pInstanceDataBuffer.length)];

        MTLRenderPassDescriptor* pRpd = pView.currentRenderPassDescriptor;
        id<MTLRenderCommandEncoder> pEnc = [pCmd renderCommandEncoderWithDescriptor:pRpd];

        [pEnc setRenderPipelineState:_pPSO];

        [pEnc setVertexBuffer:_pVertexDataBuffer offset:0 atIndex:0];
        [pEnc setVertexBuffer:pInstanceDataBuffer offset:0 atIndex:1];

        [pEnc drawIndexedPrimitives:MTLPrimitiveTypeTriangle 
                            indexCount: 6
                            indexType: MTLIndexTypeUInt16
                            indexBuffer: _pIndexBuffer
                            indexBufferOffset: 0
                            instanceCount:kNumInstances];

        [pEnc endEncoding];
        [pCmd presentDrawable:pView.currentDrawable];
        [pCmd commit];
    }
}

@end