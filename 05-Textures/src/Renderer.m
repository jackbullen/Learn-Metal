#import "Renderer.h"
#import <objc/runtime.h>

#define IMAGE_HEIGHT 28
#define IMAGE_WIDTH 28
#define IMAGE_BYTES (IMAGE_HEIGHT * IMAGE_WIDTH)

@interface Renderer()
{
    id<MTLDevice> _pDevice;
    id<MTLCommandQueue> _pCommandQueue;
    id<MTLRenderPipelineState> _pPSO;
    id<MTLBuffer> _pVertexDataBuffer;
    id<MTLBuffer> _pIndexBuffer;
    id<MTLBuffer> _pCameraDataBuffer;
    id<MTLLibrary> _pShaderLibrary;
    id<MTLDepthStencilState> _pDepthStencilState;
    id<MTLTexture> _pTexture;
    float _angle;
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
        [self buildTextures];
        [self buildBuffers];
    }
    return self;
}

- (void)dealloc 
{
    [_pDevice release];
    [_pCommandQueue release];
    [_pPSO release];
    [_pShaderLibrary release];
    [_pTexture release];
    [super dealloc];
}

- (void)buildShaders 
{
    NSError *error = nil;

    NSString *shaderSrc = [NSString stringWithContentsOfFile:@"src/shaders/05-Textures.metal" 
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

- (void)buildDepthStencilState 
{
    MTLDepthStencilDescriptor *pDsDesc = [[MTLDepthStencilDescriptor alloc] init];
    pDsDesc.depthCompareFunction = MTLCompareFunctionLess;
    pDsDesc.depthWriteEnabled = YES;

    _pDepthStencilState = [_pDevice newDepthStencilStateWithDescriptor:pDsDesc];
    [pDsDesc release];
}

- (NSArray<MPSImage *> *)loadMNISTImagesFromFile:(NSString *)filepath {

  NSFileManager *fileManager = [NSFileManager defaultManager];
  if (![fileManager fileExistsAtPath:filepath]) {
    NSLog(@"File does not exist");
    assert(false);
  }

  NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:filepath];
  if (!fileHandle) {
    NSLog(@"Failed to open file");
    assert(false);
  }

  NSData *fileData = [fileHandle readDataToEndOfFile];
  [fileHandle closeFile];

  NSMutableArray<MPSImage *> *images = [NSMutableArray array];

  for (NSUInteger i = 0; i < 1000; i++) {
    const unsigned char *imageBytes =
        (const unsigned char *)[fileData bytes] + i * IMAGE_BYTES;

    MPSImageDescriptor *imageDesc = [MPSImageDescriptor
        imageDescriptorWithChannelFormat:MPSImageFeatureChannelFormatUnorm8
                                   width:IMAGE_WIDTH
                                  height:IMAGE_HEIGHT
                         featureChannels:1];

    MPSImage *image = [[MPSImage alloc] initWithDevice:_pDevice
                                       imageDescriptor:imageDesc];

    [image writeBytes:imageBytes
           dataLayout:MPSDataLayoutHeightxWidthxFeatureChannels
           imageIndex:0];

    [images addObject:image];
  }

  return images;
}

- (NSArray<NSNumber *> *)loadMNISTLabelsFrom:(NSString *)filepath {
  NSFileManager *fileManager = [NSFileManager defaultManager];
  if (![fileManager fileExistsAtPath:filepath]) {
    NSLog(@"File does not exist");
    assert(false);
  }

  NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:filepath];
  if (!fileHandle) {
    NSLog(@"File failed to be opened");
    assert(false);
  }

  NSData *fileData = [fileHandle readDataToEndOfFile];
  [fileHandle closeFile];

  const unsigned char *labelBytes = (const unsigned char *)[fileData bytes];
  NSMutableArray<NSNumber *> *labels =
      [NSMutableArray arrayWithCapacity:1000];
  for (NSUInteger i = 0; i < 1000; i++) {
    unsigned char label = labelBytes[i];
    [labels addObject:@(label)];
  }

  return labels;
}

- (void)buildTextures 
{
    NSFileManager *fileManager = [NSFileManager defaultManager];

    // Log the label for the first image

    // NSString *labelsFilepath = @"train_labels.mnist";
    // if (![fileManager fileExistsAtPath:labelsFilepath])
    // {
    //     NSLog(@"Labels file does not exist at %@.", labelsFilepath);
    //     assert(false);
    // }

    // NSFileHandle *labelsFileHandle = [NSFileHandle fileHandleForReadingAtPath:labelsFilepath];
    // if (!labelsFileHandle)
    // {
    //     NSLog(@"Failed to open labels");
    //     assert(false);
    // }

    // NSData *labelsData = [labelsFileHandle readDataOfLength:1];
    // NSLog(@"First train label is %d.", ((const unsigned char *)[labelsData bytes])[0]);

    // Load the first image to texture

    // NSString *imagesFilepath = @"train_images.mnist";
    // if (![fileManager fileExistsAtPath:imagesFilepath]) 
    // {
    //     NSLog(@"File does not exist");
    //     assert(false);
    // }

    // NSFileHandle *imagesFileHandle = [NSFileHandle fileHandleForReadingAtPath:imagesFilepath];
    // if (!imagesFileHandle) 
    // {
    //     NSLog(@"Failed to open images");
    //     assert(false);
    // }

    // NSData *fileData = [imagesFileHandle readDataToEndOfFile];
    // [imagesFileHandle closeFile];

    // const unsigned char *imageBytes = (const unsigned char *)[fileData bytes];

    // MPSImageDescriptor *imageDesc = [MPSImageDescriptor
    //     imageDescriptorWithChannelFormat:MPSImageFeatureChannelFormatUnorm8
    //                                 width:IMAGE_WIDTH
    //                                 height:IMAGE_HEIGHT
    //                         featureChannels:1];

    // MPSImage *image = [[MPSImage alloc] initWithDevice:_pDevice
    //                                     imageDescriptor:imageDesc];

    // [image writeBytes:imageBytes
    //         dataLayout:MPSDataLayoutHeightxWidthxFeatureChannels
    //         imageIndex:0];

    NSArray<MPSImage *> *_trainImages = [self loadMNISTImagesFromFile:@"train_images.mnist"];
    NSArray<NSNumber *> *_trainLabels = [self loadMNISTLabelsFrom:@"train_labels.mnist"];

    MTLTextureDescriptor* pTextureDesc = [[MTLTextureDescriptor alloc] init];
    [pTextureDesc setWidth:IMAGE_WIDTH];
    [pTextureDesc setHeight:IMAGE_HEIGHT];
    [pTextureDesc setPixelFormat:MTLPixelFormatR8Unorm];
    [pTextureDesc setTextureType:MTLTextureType2D];
    [pTextureDesc setStorageMode:MTLStorageModeManaged];
    [pTextureDesc setUsage:MTLResourceUsageSample|MTLResourceUsageRead];

    _pTexture = [_pDevice newTextureWithDescriptor:pTextureDesc];
    _pTexture = _trainImages[100].texture;
    NSLog(@"%d", [_trainLabels[100] intValue]);
    [pTextureDesc release];
}

- (void)buildBuffers 
{
    const float s = 0.5f;

    struct VertexData vertices[] = {
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

    _pCameraDataBuffer = [_pDevice newBufferWithLength:sizeof(struct CameraData) options:MTLResourceStorageModeManaged];
}

- (void)draw:(MTKView *)pView
{
    @autoreleasepool
    {
        _angle += 0.01f;

        simd_float3 pos = {0.f, 0.f, -5.f};

        struct CameraData* pCameraData = [_pCameraDataBuffer contents];
        pCameraData->transform = matrix_multiply(makeTranslate(pos), makeYRotate(_angle));
        pCameraData->normalTransform = chopMat(pCameraData->transform);
        pCameraData->perspective = makePerspective(45.f * M_PI / 180.f, 1.f, 0.03f, 500.0f);
        pCameraData->world = makeIdentity();
        pCameraData->worldNormal = chopMat(makeIdentity());

        id<MTLCommandBuffer> pCmd = [_pCommandQueue commandBuffer];

        MTLRenderPassDescriptor* pRpd = pView.currentRenderPassDescriptor;
        id<MTLRenderCommandEncoder> pEnc = [pCmd renderCommandEncoderWithDescriptor:pRpd];

        [pEnc setRenderPipelineState:_pPSO];
        [pEnc setDepthStencilState:_pDepthStencilState];        
        [pEnc setFragmentTexture:_pTexture atIndex:0];
        [pEnc setCullMode:MTLCullModeBack];
        [pEnc setFrontFacingWinding:MTLWindingCounterClockwise];

        [pEnc setVertexBuffer:_pVertexDataBuffer offset:0 atIndex:0];
        [pEnc setVertexBuffer:_pCameraDataBuffer offset:0 atIndex:1];

        [pEnc drawIndexedPrimitives:MTLPrimitiveTypeTriangle 
                        indexCount:36 
                        indexType:MTLIndexTypeUInt16 
                        indexBuffer:_pIndexBuffer 
                        indexBufferOffset:0 
                        instanceCount:1];

        [pEnc endEncoding];
        [pCmd presentDrawable:pView.currentDrawable];
        [pCmd commit];
    }
}

@end