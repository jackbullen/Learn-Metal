#import <Metal/Metal.h>
#import <AppKit/AppKit.h>
#import <MetalKit/MetalKit.h>
#import <simd/simd.h>

#define kNumInstances 32
static const size_t kMaxFramesInFlight = 3;

namespace math
{
    constexpr simd::float3 add( const simd::float3& a, const simd::float3& b );
    constexpr simd_float4x4 makeIdentity();
    simd::float4x4 makePerspective();
    simd::float4x4 makeXRotate( float angleRadians );
    simd::float4x4 makeYRotate( float angleRadians );
    simd::float4x4 makeZRotate( float angleRadians );
    simd::float4x4 makeTranslate( const simd::float3& v );
    simd::float4x4 makeScale( const simd::float3& v );
}

struct InstanceData
{
    simd::float4x4 instanceTransform;
    simd::float4 instanceColor;
};

struct CameraData
{
    simd::float4x4 perspectiveTransform;
    simd::float4x4 worldTransform;
};

@interface Renderer: NSObject
- (instancetype)initWithDevice:(id<MTLDevice>)device;
- (void)buildShaders;
- (void)buildDepthStencilStates;
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
    [_pWindow setTitle:@"05 - Perspective"];
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

namespace math
{
    constexpr simd::float3 add(const simd::float3& a, const simd::float3& b)
    {
        return { a.x + b.x, a.y + b.y, a.z + b.z };
    }

    constexpr simd_float4x4 makeIdentity()
    {
        return (simd_float4x4){ (simd::float4){ 1.f, 0.f, 0.f, 0.f },
                                (simd::float4){ 0.f, 1.f, 0.f, 0.f },
                                (simd::float4){ 0.f, 0.f, 1.f, 0.f },
                                (simd::float4){ 0.f, 0.f, 0.f, 1.f } };
    }

    simd::float4x4 makePerspective(float fovRadians, float aspect, float znear, float zfar)
    {
        float ys = 1.f / tanf(fovRadians * 0.5f);
        float xs = ys / aspect;
        float zs = zfar / ( znear - zfar );
        return simd_matrix_from_rows((simd::float4){ xs, 0.0f, 0.0f, 0.0f },
                                     (simd::float4){ 0.0f, ys, 0.0f, 0.0f },
                                     (simd::float4){ 0.0f, 0.0f, zs, znear * zs },
                                     (simd::float4){ 0, 0, -1, 0 });
    }

    simd::float4x4 makeXRotate(float angleRadians)
    {
        const float a = angleRadians;
        return simd_matrix_from_rows((simd::float4){ 1.0f, 0.0f, 0.0f, 0.0f },
                                     (simd::float4){ 0.0f, cosf(a), sinf(a), 0.0f },
                                     (simd::float4){ 0.0f, -sinf(a), cosf(a), 0.0f },
                                     (simd::float4){ 0.0f, 0.0f, 0.0f, 1.0f });
    }

    simd::float4x4 makeYRotate(float angleRadians)
    {
        const float a = angleRadians;
        return simd_matrix_from_rows((simd::float4){ cosf(a), 0.0f, sinf(a), 0.0f },
                                     (simd::float4){ 0.0f, 1.0f, 0.0f, 0.0f },
                                     (simd::float4){ -sinf(a), 0.0f, cosf(a), 0.0f },
                                     (simd::float4){ 0.0f, 0.0f, 0.0f, 1.0f });
    }

    simd::float4x4 makeZRotate(float angleRadians)
    {
        const float a = angleRadians;
        return simd_matrix_from_rows((simd::float4){ cosf(a), sinf(a), 0.0f, 0.0f },
                                     (simd::float4){ -sinf(a), cosf(a), 0.0f, 0.0f },
                                     (simd::float4){ 0.0f, 0.0f, 1.0f, 0.0f },
                                     (simd::float4){ 0.0f, 0.0f, 0.0f, 1.0f });
    }

    simd::float4x4 makeTranslate(const simd::float3& v)
    {
        const simd::float4 col0 = { 1.0f, 0.0f, 0.0f, 0.0f };
        const simd::float4 col1 = { 0.0f, 1.0f, 0.0f, 0.0f };
        const simd::float4 col2 = { 0.0f, 0.0f, 1.0f, 0.0f };
        const simd::float4 col3 = { v.x, v.y, v.z, 1.0f };
        return simd_matrix( col0, col1, col2, col3 );
    }

    simd::float4x4 makeScale(const simd::float3& v)
    {
        return simd_matrix((simd::float4){ v.x, 0, 0, 0 },
                           (simd::float4){ 0, v.y, 0, 0 },
                           (simd::float4){ 0, 0, v.z, 0 },
                           (simd::float4){ 0, 0, 0, 1.0 });
    }
}

@interface Renderer()
{
    id<MTLDevice> _pDevice;
    id<MTLCommandQueue> _pCommandQueue;
    id<MTLLibrary> _pShaderLibrary;
    id<MTLRenderPipelineState> _pPSO;
    id<MTLDepthStencilState> _pDepthStencilState;
    id<MTLBuffer> _pVertexDataBuffer;
    id<MTLBuffer> _pInstanceDataBuffer[kMaxFramesInFlight];
    id<MTLBuffer> _pCameraDataBuffer[kMaxFramesInFlight];
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
        [self buildDepthStencilStates];
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
    for (int i = 0; i < kMaxFramesInFlight; i++)
    {
        _pCameraDataBuffer[i] = nil;
    }
    _pShaderLibrary = nil;
    _pDepthStencilState = nil;
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
            float3 position; \n\
        }; \n\
        struct InstanceData \n\
        { \n\
            float4x4 instanceTransform; \n\
            float4 instanceColor; \n\
        }; \n\
        struct CameraData \n\
        { \n\
            float4x4 perspectiveTransform; \n\
            float4x4 worldTransform; \n\
        }; \n\
        v2f vertex vertexMain(device const VertexData* vertexData [[buffer(0)]], \n\
                              device const InstanceData* instanceData [[buffer(1)]], \n\
                              device const CameraData& cameraData [[buffer(2)]], \n\
                              uint vertexId [[vertex_id]], \n\
                              uint instanceId [[instance_id]]) \n\
        { \n\
            v2f o; \n\
            float4 pos = float4(vertexData[vertexId].position, 1.0); \n\
            pos = instanceData[instanceId].instanceTransform * pos; \n\
            pos = cameraData.perspectiveTransform * cameraData.worldTransform * pos; \n\
            o.position = pos; \n\
            o.color = half3(instanceData[instanceId].instanceColor.rgb); \n\
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
    [pDesc setDepthAttachmentPixelFormat:MTLPixelFormatDepth16Unorm];

    _pPSO = [_pDevice newRenderPipelineStateWithDescriptor:pDesc error:&error];
    if (!_pPSO) 
    {
        NSLog(@"Failed to create render pipeline state: %@", error.localizedDescription);
        return;
    }
}

- (void)buildDepthStencilStates 
{
    MTLDepthStencilDescriptor* pDsDesc = [[MTLDepthStencilDescriptor alloc] init];
    pDsDesc.depthCompareFunction = MTLCompareFunctionLess;
    pDsDesc.depthWriteEnabled = YES;

    _pDepthStencilState = [_pDevice newDepthStencilStateWithDescriptor:pDsDesc];
    pDsDesc = nil;
}

- (void)buildBuffers
{
    const float s = 0.5f;

    simd::float3 vertices[] = {
        { -s, -s, +s },
        { +s, -s, +s },
        { +s, +s, +s },
        { -s, +s, +s },

        { -s, -s, -s },
        { -s, +s, -s },
        { +s, +s, -s },
        { +s, -s, -s }
    };

    uint16_t indices[] = {
        0, 1, 2, /* front */
        2, 3, 0,

        1, 7, 6, /* right */
        6, 2, 1,

        7, 4, 5, /* back */
        5, 6, 7,

        4, 0, 3, /* left */
        3, 5, 4,

        3, 2, 6, /* top */
        6, 5, 3,

        4, 7, 1, /* bottom */
        1, 0, 4
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

    const size_t cameraDataSize = sizeof(CameraData);
    for (size_t i = 0; i < kMaxFramesInFlight; i++)
    {
        _pCameraDataBuffer[i] = [_pDevice newBufferWithLength:cameraDataSize options:MTLResourceStorageModeManaged];
    }
}

- (void)draw:(MTKView *)pView
{
    @autoreleasepool
    {
        // Update state 

        _frame = (_frame + 1) % kMaxFramesInFlight;
        id<MTLBuffer> pInstanceDataBuffer = _pInstanceDataBuffer[_frame];
        InstanceData* pInstanceData = reinterpret_cast< InstanceData *>( pInstanceDataBuffer.contents );

        _angle += 0.01f;

        const float scl = 0.1f;
        simd::float3 objectPosition = {0.f, 0.f, -5.f};
        simd::float4x4 rt = math::makeTranslate(objectPosition);
        simd::float4x4 rr = math::makeYRotate(_angle);
        simd::float4x4 objectRot = rt * rr;
        
        for ( size_t i = 0; i < kNumInstances; ++i )
        {
            float iDivNumInstances = i / (float)kNumInstances;
            float xoff = (iDivNumInstances * 2.0f - 1.0f) + (1.f/kNumInstances);
            float yoff = sin(( iDivNumInstances + _angle ) * 2.0f * M_PI);

            simd::float4x4 scale = math::makeScale((simd::float3){scl, scl, scl});
            simd::float4x4 transformInstance = math::makeTranslate((simd::float3){xoff, yoff, 0.f}) * scale;

            // transform instances then object rotation. results in all instances rotating around a common angle, 
            // rather than having the rotation be local to each instance.
            pInstanceData[i].instanceTransform = objectRot * transformInstance;

            float r = iDivNumInstances;
            float g = 1.0f - r;
            float b = sinf(M_PI * 2.0f * iDivNumInstances);
            pInstanceData[i].instanceColor = (simd::float4){ r, g, b, 1.0f };
        }
        [pInstanceDataBuffer didModifyRange:NSMakeRange(0, pInstanceDataBuffer.length)];

        id<MTLBuffer> pCameraDataBuffer = _pCameraDataBuffer[_frame];
        CameraData* pCameraData = reinterpret_cast<CameraData*>(pCameraDataBuffer.contents);
        pCameraData->perspectiveTransform = math::makePerspective(45.f * M_PI / 180.f, 1.f, 0.03f, 500.0f);
        pCameraData->worldTransform = math::makeIdentity();
        [pCameraDataBuffer didModifyRange:NSMakeRange(0, pCameraDataBuffer.length)];

        // Send commands

        id<MTLCommandBuffer> pCmd = [_pCommandQueue commandBuffer];

        [pCmd addCompletedHandler:^(id<MTLCommandBuffer> buffer) {
            dispatch_semaphore_signal(_semaphore);
        }];

        MTLRenderPassDescriptor* pRpd = pView.currentRenderPassDescriptor;
        id<MTLRenderCommandEncoder> pEnc = [pCmd renderCommandEncoderWithDescriptor:pRpd];

        [pEnc setRenderPipelineState:_pPSO];
        [pEnc setDepthStencilState:_pDepthStencilState];
        [pEnc setCullMode:MTLCullModeBack];
        [pEnc setFrontFacingWinding:MTLWindingCounterClockwise];

        [pEnc setVertexBuffer:_pVertexDataBuffer offset:0 atIndex:0];
        [pEnc setVertexBuffer:pInstanceDataBuffer offset:0 atIndex:1];
        [pEnc setVertexBuffer:pCameraDataBuffer offset:0 atIndex:2];

        [pEnc drawIndexedPrimitives:MTLPrimitiveTypeTriangle 
                            indexCount: 36
                            indexType: MTLIndexTypeUInt16
                            indexBuffer: _pIndexBuffer
                            indexBufferOffset: 0
                            instanceCount:kNumInstances];

        [pEnc endEncoding];
        [pCmd presentDrawable:pView.currentDrawable];
        
        // Everything is ready, now wait for semaphore
        dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
        [pCmd commit];
    }
}

@end