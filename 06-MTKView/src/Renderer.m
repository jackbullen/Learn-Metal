#import "Renderer.h"
#import <objc/runtime.h>

@interface Renderer () {
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
  float _loc[3];
  int _currKey;
}
@end

@implementation Renderer

- (instancetype)initWithDevice:(id<MTLDevice>)device {
  self = [super init];
  if (self) {
    _pDevice = device;
    _pCommandQueue = [_pDevice newCommandQueue];
    _angle = 0;
    _loc[0] = 0.f;
    _loc[1] = 0.f;
    _loc[2] = -10.f;
    _currKey = -1;
    [self buildShaders];
    [self buildTextures];
    [self buildBuffers];
  }
  return self;
}

- (void)dealloc {
  [_pDevice release];
  [_pCommandQueue release];
  [_pPSO release];
  [_pShaderLibrary release];
  [_pTexture release];
  [super dealloc];
}

- (void)buildShaders {
  NSError *error = nil;

  NSString *shaderSrc =
      [NSString stringWithContentsOfFile:@"src/shaders/shade.metal"
                                encoding:NSUTF8StringEncoding
                                   error:&error];

  _pShaderLibrary = [_pDevice newLibraryWithSource:shaderSrc
                                           options:nil
                                             error:&error];
  if (!_pShaderLibrary) {
    NSLog(@"Could not create shader library: %@", error.localizedDescription);
    return;
  }

  id<MTLFunction> pVertexFn =
      [_pShaderLibrary newFunctionWithName:@"vertexMain"];
  if (!pVertexFn) {
    NSLog(@"Failed to load vertex function");
    return;
  }

  id<MTLFunction> pFragFn =
      [_pShaderLibrary newFunctionWithName:@"fragmentMain"];
  if (!pFragFn) {
    NSLog(@"Failed to load fragment function");
    return;
  }

  MTLRenderPipelineDescriptor *pDesc =
      [[MTLRenderPipelineDescriptor alloc] init];
  pDesc.vertexFunction = pVertexFn;
  pDesc.fragmentFunction = pFragFn;
  pDesc.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm_sRGB;
  [pDesc setDepthAttachmentPixelFormat:MTLPixelFormatDepth16Unorm];

  _pPSO = [_pDevice newRenderPipelineStateWithDescriptor:pDesc error:&error];
  if (!_pPSO) {
    NSLog(@"Failed to create render pipeline state: %@",
          error.localizedDescription);
    return;
  }
}

- (void)buildDepthStencilState {
  MTLDepthStencilDescriptor *pDsDesc = [[MTLDepthStencilDescriptor alloc] init];
  pDsDesc.depthCompareFunction = MTLCompareFunctionLess;
  pDsDesc.depthWriteEnabled = YES;

  _pDepthStencilState = [_pDevice newDepthStencilStateWithDescriptor:pDsDesc];
  [pDsDesc release];
}

- (void)buildTextures {
  MTLTextureDescriptor *pTextureDesc = [[MTLTextureDescriptor alloc] init];
  [pTextureDesc setWidth:8];
  [pTextureDesc setHeight:8];
  [pTextureDesc setPixelFormat:MTLPixelFormatR8Unorm];
  [pTextureDesc setTextureType:MTLTextureType2D];
  [pTextureDesc setStorageMode:MTLStorageModeManaged];
  [pTextureDesc setUsage:MTLResourceUsageSample | MTLResourceUsageRead];

  _pTexture = [_pDevice newTextureWithDescriptor:pTextureDesc];
  [pTextureDesc release];

  // Set the _pTexture data...
}

- (void)buildBuffers {
  const float s = 0.5f;

  struct VertexData vertices[] = {
      //                                         Texture
      //   Positions           Normals         Coordinates
      {{-s, -s, +s}, {0.f, 0.f, 1.f}, {0.f, 1.f}},
      {{+s, -s, +s}, {0.f, 0.f, 1.f}, {1.f, 1.f}},
      {{+s, +s, +s}, {0.f, 0.f, 1.f}, {1.f, 0.f}},
      {{-s, +s, +s}, {0.f, 0.f, 1.f}, {0.f, 0.f}},

      {{+s, -s, +s}, {1.f, 0.f, 0.f}, {0.f, 1.f}},
      {{+s, -s, -s}, {1.f, 0.f, 0.f}, {1.f, 1.f}},
      {{+s, +s, -s}, {1.f, 0.f, 0.f}, {1.f, 0.f}},
      {{+s, +s, +s}, {1.f, 0.f, 0.f}, {0.f, 0.f}},

      {{+s, -s, -s}, {0.f, 0.f, -1.f}, {0.f, 1.f}},
      {{-s, -s, -s}, {0.f, 0.f, -1.f}, {1.f, 1.f}},
      {{-s, +s, -s}, {0.f, 0.f, -1.f}, {1.f, 0.f}},
      {{+s, +s, -s}, {0.f, 0.f, -1.f}, {0.f, 0.f}},

      {{-s, -s, -s}, {-1.f, 0.f, 0.f}, {0.f, 1.f}},
      {{-s, -s, +s}, {-1.f, 0.f, 0.f}, {1.f, 1.f}},
      {{-s, +s, +s}, {-1.f, 0.f, 0.f}, {1.f, 0.f}},
      {{-s, +s, -s}, {-1.f, 0.f, 0.f}, {0.f, 0.f}},

      {{-s, +s, +s}, {0.f, 1.f, 0.f}, {0.f, 1.f}},
      {{+s, +s, +s}, {0.f, 1.f, 0.f}, {1.f, 1.f}},
      {{+s, +s, -s}, {0.f, 1.f, 0.f}, {1.f, 0.f}},
      {{-s, +s, -s}, {0.f, 1.f, 0.f}, {0.f, 0.f}},

      {{-s, -s, -s}, {0.f, -1.f, 0.f}, {0.f, 1.f}},
      {{+s, -s, -s}, {0.f, -1.f, 0.f}, {1.f, 1.f}},
      {{+s, -s, +s}, {0.f, -1.f, 0.f}, {1.f, 0.f}},
      {{-s, -s, +s}, {0.f, -1.f, 0.f}, {0.f, 0.f}}};

  uint16_t indices[] = {
      0,  1,  2,  2,  3,  0,  /* front */
      4,  5,  6,  6,  7,  4,  /* right */
      8,  9,  10, 10, 11, 8,  /* back */
      12, 13, 14, 14, 15, 12, /* left */
      16, 17, 18, 18, 19, 16, /* top */
      20, 21, 22, 22, 23, 20, /* bottom */
  };

  const size_t verticesDataSize = sizeof(vertices);
  const size_t indicesDataSize = sizeof(indices);

  _pVertexDataBuffer =
      [_pDevice newBufferWithBytes:vertices
                            length:verticesDataSize
                           options:MTLResourceStorageModeManaged];
  [_pVertexDataBuffer didModifyRange:NSMakeRange(0, _pVertexDataBuffer.length)];

  _pIndexBuffer = [_pDevice newBufferWithBytes:indices
                                        length:indicesDataSize
                                       options:MTLResourceStorageModeManaged];
  [_pIndexBuffer didModifyRange:NSMakeRange(0, _pIndexBuffer.length)];

  _pCameraDataBuffer =
      [_pDevice newBufferWithLength:sizeof(struct CameraData)
                            options:MTLResourceStorageModeManaged];
}

- (void)keyDownEvent:(NSEvent *)event {
  NSLog(@"Renderer received key down event: %d", (int)event.keyCode);
  _currKey = (int)event.keyCode;
}

- (void)keyUpEvent:(NSEvent *)event {
  NSLog(@"Renderer received key up event: %d", (int)event.keyCode);
  _currKey = -1; // assumes only one key is pressed at a time
}

- (void)draw:(MTKView *)pView {
  @autoreleasepool {

    if (_currKey == 2) {
      _loc[0] += 0.1f;
    } else if (_currKey == 0) {
      _loc[0] -= 0.1f;
    } else if (_currKey == 13) {
      _loc[1] += 0.1f;
    } else if (_currKey == 1) {
      _loc[1] -= 0.1f;
    } else if (_currKey == 49) {
      _loc[2] += 0.5f; // lol
    }

    simd_float3 pos = {_loc[0], _loc[1], _loc[2]};

    struct CameraData *pCameraData = [_pCameraDataBuffer contents];
    pCameraData->transform =
        matrix_multiply(makeTranslate(pos), makeZRotate(_angle));
    pCameraData->normalTransform = chopMat(pCameraData->transform);
    pCameraData->perspective =
        makePerspective(45.f * M_PI / 180.f, 1.f, 0.03f, 500.0f);
    pCameraData->world = makeIdentity();
    pCameraData->worldNormal = chopMat(makeIdentity());

    id<MTLCommandBuffer> pCmd = [_pCommandQueue commandBuffer];

    MTLRenderPassDescriptor *pRpd = pView.currentRenderPassDescriptor;
    id<MTLRenderCommandEncoder> pEnc =
        [pCmd renderCommandEncoderWithDescriptor:pRpd];

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