#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import <AppKit/AppKit.h>
#import <simd/simd.h>

#define kNumRows 10
#define kNumColumns 10
#define kNumStacks 10
#define kNumInstances (kNumRows * kNumColumns * kNumStacks)
#define kTextureWidth 128
#define kTextureHeight 128
static const size_t kMaxFramesInFlight = 3;

namespace math
{
    constexpr simd::float3 add(const simd::float3& a, const simd::float3& b);
    constexpr simd_float4x4 makeIdentity();
    simd::float4x4 makePerspective();
    simd::float4x4 makeXRotate(float angleRadians);
    simd::float4x4 makeYRotate(float angleRadians);
    simd::float4x4 makeZRotate(float angleRadians);
    simd::float4x4 makeTranslate(const simd::float3& v);
    simd::float4x4 makeScale(const simd::float3& v);
    simd::float3x3 chopMat(const simd::float4x4& mat);
}

struct VertexData
{
    simd::float3 position;
    simd::float3 normal;
    simd::float2 texcoord;
};

struct InstanceData
{
    simd::float4x4 instanceTransform;
    simd::float3x3 instanceNormalTransform;
    simd::float4 instanceColor;
};

struct CameraData
{
    simd::float4x4 perspectiveTransform;
    simd::float4x4 worldTransform;
    simd::float3x3 worldNormalTransform;
};

@interface Renderer: NSObject
- (instancetype)initWithDevice:(id<MTLDevice>)device;
- (void)buildShaders;
- (void)buildComputePipeline;
- (void)buildDepthStencilStates;
- (void)generateMandelbrotTexture:(id<MTLCommandBuffer>)pCommandBuffer;
- (void)buildTextures;
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
    [_pWindow setTitle:@"09 - Compute to Render"];
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

    simd::float3x3 chopMat(const simd::float4x4& mat)
    {
        return simd_matrix(mat.columns[0].xyz, mat.columns[1].xyz, mat.columns[2].xyz);
    }
}

@interface Renderer()
{
    id<MTLDevice> _pDevice;
    id<MTLCommandQueue> _pCommandQueue;
    id<MTLLibrary> _pShaderLibrary;
    id<MTLRenderPipelineState> _pPSO;
    id<MTLComputePipelineState> _pComputePSO;
    id<MTLDepthStencilState> _pDepthStencilState;
    id<MTLTexture> _pTexture;
    id<MTLBuffer> _pVertexDataBuffer;
    id<MTLBuffer> _pInstanceDataBuffer[kMaxFramesInFlight];
    id<MTLBuffer> _pCameraDataBuffer[kMaxFramesInFlight];
    id<MTLBuffer> _pIndexBuffer;
    id<MTLBuffer> _pTextureAnimationBuffer;
    int _frame;
    float _angle;
    uint _animationIndex;
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
        [self buildComputePipeline];
        [self buildDepthStencilStates];
        [self buildTextures];
        [self buildBuffers];
        _semaphore = dispatch_semaphore_create(kMaxFramesInFlight);
    }
    return self;
}

- (void)dealloc 
{
    _pDevice = nil;
    _pPSO = nil;
    _pComputePSO = nil;
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
    _pTexture = nil;
    _pTextureAnimationBuffer = nil;
    [super dealloc];
}

-(void)buildShaders
{
    NSError* error = nil;

    NSString* shaderSrc = [NSString stringWithContentsOfFile:@"src/shaders/07-texturing.metal" 
                                        encoding:NSUTF8StringEncoding 
                                            error:&error];

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

- (void)buildComputePipeline
{
    NSError* error = nil;

    NSString* kernelSrc = [NSString stringWithContentsOfFile:@"src/shaders/09-mandelbrot.metal" 
                                        encoding:NSUTF8StringEncoding 
                                            error:&error];
    
    id<MTLLibrary> pComputeLibrary = [_pDevice newLibraryWithSource:kernelSrc options:nil error:&error];
    if (!pComputeLibrary)
    {
        NSLog(@"Could not create shader library: %@", error.localizedDescription);   
    }

    id<MTLFunction> pMandelbrot = [pComputeLibrary newFunctionWithName:@"mandelbrot"];

    _pComputePSO = [_pDevice newComputePipelineStateWithFunction:pMandelbrot error:&error];
    if (!_pComputePSO)
    {
        NSLog(@"Could not create compute pipeline state: %@", error.localizedDescription);
    }

    pMandelbrot = nil;
    pComputeLibrary = nil;
}

- (void)buildDepthStencilStates 
{
    MTLDepthStencilDescriptor* pDsDesc = [[MTLDepthStencilDescriptor alloc] init];
    pDsDesc.depthCompareFunction = MTLCompareFunctionLess;
    pDsDesc.depthWriteEnabled = YES;

    _pDepthStencilState = [_pDevice newDepthStencilStateWithDescriptor:pDsDesc];
    pDsDesc = nil;
}

- (void)buildTextures
{
    MTLTextureDescriptor* pTextureDesc = [[MTLTextureDescriptor alloc] init];
    [pTextureDesc setWidth:kTextureWidth];
    [pTextureDesc setHeight:kTextureHeight];
    [pTextureDesc setPixelFormat:MTLPixelFormatBGRA8Unorm];
    [pTextureDesc setTextureType:MTLTextureType2D];
    [pTextureDesc setStorageMode:MTLStorageModeManaged];
    [pTextureDesc setUsage:MTLResourceUsageSample | MTLResourceUsageRead | MTLResourceUsageWrite];

    _pTexture = [_pDevice newTextureWithDescriptor:pTextureDesc];
    pTextureDesc = nil;
}

- (void)buildBuffers
{
    const float s = 0.5f;

    VertexData vertices[] = {
        //                                         Texture
        //   Positions           Normals         Coordinates
        { { -s, -s, +s }, {  0.f,  0.f,  1.f }, { 0.f, 1.f } },
        { { +s, -s, +s }, {  0.f,  0.f,  1.f }, { 1.f, 1.f } },
        { { +s, +s, +s }, {  0.f,  0.f,  1.f }, { 1.f, 0.f } },
        { { -s, +s, +s }, {  0.f,  0.f,  1.f }, { 0.f, 0.f } },

        { { +s, -s, +s }, {  1.f,  0.f,  0.f }, { 0.f, 1.f } },
        { { +s, -s, -s }, {  1.f,  0.f,  0.f }, { 1.f, 1.f } },
        { { +s, +s, -s }, {  1.f,  0.f,  0.f }, { 1.f, 0.f } },
        { { +s, +s, +s }, {  1.f,  0.f,  0.f }, { 0.f, 0.f } },

        { { +s, -s, -s }, {  0.f,  0.f, -1.f }, { 0.f, 1.f } },
        { { -s, -s, -s }, {  0.f,  0.f, -1.f }, { 1.f, 1.f } },
        { { -s, +s, -s }, {  0.f,  0.f, -1.f }, { 1.f, 0.f } },
        { { +s, +s, -s }, {  0.f,  0.f, -1.f }, { 0.f, 0.f } },

        { { -s, -s, -s }, { -1.f,  0.f,  0.f }, { 0.f, 1.f } },
        { { -s, -s, +s }, { -1.f,  0.f,  0.f }, { 1.f, 1.f } },
        { { -s, +s, +s }, { -1.f,  0.f,  0.f }, { 1.f, 0.f } },
        { { -s, +s, -s }, { -1.f,  0.f,  0.f }, { 0.f, 0.f } },

        { { -s, +s, +s }, {  0.f,  1.f,  0.f }, { 0.f, 1.f } },
        { { +s, +s, +s }, {  0.f,  1.f,  0.f }, { 1.f, 1.f } },
        { { +s, +s, -s }, {  0.f,  1.f,  0.f }, { 1.f, 0.f } },
        { { -s, +s, -s }, {  0.f,  1.f,  0.f }, { 0.f, 0.f } },

        { { -s, -s, -s }, {  0.f, -1.f,  0.f }, { 0.f, 1.f } },
        { { +s, -s, -s }, {  0.f, -1.f,  0.f }, { 1.f, 1.f } },
        { { +s, -s, +s }, {  0.f, -1.f,  0.f }, { 1.f, 0.f } },
        { { -s, -s, +s }, {  0.f, -1.f,  0.f }, { 0.f, 0.f } }
    };

    uint16_t indices[] = {
         0,  1,  2,  2,  3,  0, /* front */
         4,  5,  6,  6,  7,  4, /* right */
         8,  9, 10, 10, 11,  8, /* back */
        12, 13, 14, 14, 15, 12, /* left */
        16, 17, 18, 18, 19, 16, /* top */
        20, 21, 22, 22, 23, 20, /* bottom */
    };

    const size_t verticesDataSize = sizeof(vertices);
    const size_t indicesDataSize = sizeof(indices);

    _pVertexDataBuffer = [_pDevice newBufferWithBytes:vertices length:verticesDataSize options:MTLResourceStorageModeManaged];
    [_pVertexDataBuffer didModifyRange:NSMakeRange(0, _pVertexDataBuffer.length)];

    _pIndexBuffer = [_pDevice newBufferWithBytes:indices length:indicesDataSize options:MTLResourceStorageModeManaged];
    [_pIndexBuffer didModifyRange:NSMakeRange(0, _pIndexBuffer.length)];

    const size_t instanceDataSize = kNumInstances * sizeof(InstanceData);
    for (int i = 0; i < kMaxFramesInFlight; i++)
    {
        _pInstanceDataBuffer[i] = [_pDevice newBufferWithLength:instanceDataSize options:MTLResourceStorageModeManaged];
    }

    const size_t cameraDataSize = sizeof(CameraData);
    for (size_t i = 0; i < kMaxFramesInFlight; i++)
    {
        _pCameraDataBuffer[i] = [_pDevice newBufferWithLength:cameraDataSize options:MTLResourceStorageModeManaged];
    }

    _pTextureAnimationBuffer = [_pDevice newBufferWithLength:sizeof(uint) options:MTLResourceStorageModeManaged];
}

- (void)generateMandelbrotTexture:(id<MTLCommandBuffer>)pCommandBuffer
{
    uint* ptr = reinterpret_cast<uint*>([_pTextureAnimationBuffer contents]);
    *ptr = (_animationIndex++) % 5000;
    [_pTextureAnimationBuffer didModifyRange:NSMakeRange(0, _pTextureAnimationBuffer.length)];

    id<MTLComputeCommandEncoder> pComputeEncoder = [pCommandBuffer computeCommandEncoder];
    [pComputeEncoder setComputePipelineState:_pComputePSO];
    [pComputeEncoder setTexture:_pTexture atIndex:0];
    [pComputeEncoder setBuffer:_pTextureAnimationBuffer offset:0 atIndex:0];

    MTLSize gridSize = MTLSizeMake(kTextureWidth, kTextureHeight, 1);
    NSUInteger threadGroupSize = [_pComputePSO maxTotalThreadsPerThreadgroup];
    MTLSize threadgroupSize = MTLSizeMake(threadGroupSize, 1, 1);

    [pComputeEncoder dispatchThreads:gridSize threadsPerThreadgroup:threadgroupSize];
    [pComputeEncoder endEncoding];
}

- (void)draw:(MTKView *)pView
{
    @autoreleasepool
    {
        // Update state 

        _frame = (_frame + 1) % kMaxFramesInFlight;
        id<MTLBuffer> pInstanceDataBuffer = _pInstanceDataBuffer[_frame];
        InstanceData* pInstanceData = reinterpret_cast< InstanceData *>( pInstanceDataBuffer.contents );

        _angle += 0.002f;

        const float scl = .2f;

        simd::float3 objectPosition = {0.f, 0.f, -5.f};
        simd::float4x4 rr = math::makeYRotate(_angle);
        simd::float4x4 ry = math::makeXRotate(_angle);
        simd::float4x4 objectRot = rr * ry;
        simd::float4x4 objectTranslate = math::makeTranslate({objectPosition.x, objectPosition.y, objectPosition.z});
        simd::float4x4 objectTransform = objectTranslate * objectRot;

        size_t ix = 0, iy = 0, iz = 0;
        for ( size_t i = 0; i < kNumInstances; ++i )
        {
            if (ix == kNumRows) 
            { // go to next column
                ix = 0;
                iy += 1;
            }
            if (iy == kNumRows)
            { // go to next stack
                iy = 0;
                iz += 1;
            }

            float x = ((float)ix - (float)kNumRows/2.f) * (2.f * scl) + scl;
            float y = ((float)iy - (float)kNumColumns/2.f) * (2.f * scl) + scl;
            float z = ((float)iz - (float)kNumStacks/2.f) * (2. * scl);
            simd::float3 instancePosition = {x, y, z};
            simd::float4x4 instanceTranslate = math::makeTranslate(instancePosition);
            simd::float4x4 scale = math::makeScale((simd::float3){scl, scl, scl});
            simd::float4x4 zrot = math::makeZRotate(10*_angle * sinf((float)ix));
            simd::float4x4 yrot = math::makeYRotate(_angle * cosf((float)iy));
            simd::float4x4 instanceRot = yrot * zrot;
            simd::float4x4 instanceTransform = instanceTranslate * instanceRot;

            // i would like to rename instanceTransform on the InstanceData struct
            // here i am calling instanceTransform the transformation that is happening to each local instance
            //                 which consists of its rotation and then moving to its correct location
            // then objectTransform is the transform on the object made up of all instances
            pInstanceData[i].instanceTransform = objectTransform * instanceTransform * scale;
            pInstanceData[i].instanceNormalTransform = math::chopMat(pInstanceData[i].instanceTransform);

            float iDivNumInstances = i / (float)kNumInstances;
            float r = iDivNumInstances;
            float g = 1.0f - r;
            float b = sinf(M_PI * 2.0f * iDivNumInstances);
            pInstanceData[i].instanceColor = (simd::float4){ r, g, b, 1.0f };

            ix++;
        }
        [pInstanceDataBuffer didModifyRange:NSMakeRange(0, pInstanceDataBuffer.length)];

        id<MTLBuffer> pCameraDataBuffer = _pCameraDataBuffer[_frame];
        CameraData* pCameraData = reinterpret_cast<CameraData*>(pCameraDataBuffer.contents);
        pCameraData->perspectiveTransform = math::makePerspective(45.f * M_PI / 180.f, 1.f, 0.03f, 500.0f);
        pCameraData->worldTransform = math::makeIdentity();
        pCameraData->worldNormalTransform = math::chopMat(math::makeIdentity());
        [pCameraDataBuffer didModifyRange:NSMakeRange(0, pCameraDataBuffer.length)];

        id<MTLCommandBuffer> pCmd = [_pCommandQueue commandBuffer];

        [pCmd addCompletedHandler:^(id<MTLCommandBuffer> buffer) {
            dispatch_semaphore_signal(_semaphore);
        }];

        [self generateMandelbrotTexture:pCmd];

        MTLRenderPassDescriptor* pRpd = pView.currentRenderPassDescriptor;
        id<MTLRenderCommandEncoder> pEnc = [pCmd renderCommandEncoderWithDescriptor:pRpd];

        [pEnc setRenderPipelineState:_pPSO];
        [pEnc setDepthStencilState:_pDepthStencilState];
        [pEnc setFragmentTexture:_pTexture atIndex:0];
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