#import "Renderer.h"
#include "FlyCamera.h"
#import <objc/runtime.h>

#define W_KEY 13
#define A_KEY 0
#define S_KEY 1
#define D_KEY 2
#define SPACEBAR 49

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
  bool _pControls[50];
  NSPoint previousMouse;
  NSPoint currentMouse;
  float eye[3];
  float look[3];
  float up[3];
  float view[16];
  float delta_time_seconds;
  float eye_speed;
  float degrees_per_cursor_move;
  float max_pitch_rotation_degrees;
}
@end

@implementation Renderer

- (instancetype)initWithDevice:(id<MTLDevice>)device {
  self = [super init];
  if (self) {
    // Scene
    _angle = 0;
    _loc[0] = 0.f;
    _loc[1] = 0.f;
    _loc[2] = -10.f;
    memset(_pControls, 0, sizeof(_pControls));
    previousMouse = NSMakePoint(0.0, 0.0);
    currentMouse = NSMakePoint(0.0, 0.0);

    // Camera
    eye[0] = 0, eye[1] = 0, eye[2] = 10;
    look[0] = 0, look[1] = 0, look[2] = -1;
    up[0] = 0, up[1] = 1, up[2] = 0;
    memset(view, 0, sizeof(view));
    delta_time_seconds = 1.0;
    eye_speed = 0.05;
    degrees_per_cursor_move = 0.5;
    max_pitch_rotation_degrees = 85;

    // Metal
    _pDevice = device;
    _pCommandQueue = [_pDevice newCommandQueue];
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
  _pControls[event.keyCode] = true;
}

- (void)keyUpEvent:(NSEvent *)event {
  _pControls[event.keyCode] = false;
}

- (void)mouseDownEvent:(NSPoint *)loc {
  currentMouse = *loc;
  previousMouse = *loc;
}

- (void)mouseUpEvent:(NSPoint *)loc {
  currentMouse = *loc;
  previousMouse = *loc;
}

- (void)mouseDraggedEvent:(NSPoint *)loc {
  previousMouse = currentMouse;
  currentMouse = *loc;
}

- (void)draw:(MTKView *)pView {
  @autoreleasepool {

    if (_pControls[D_KEY]) {
      _loc[0] += 0.08f;
    }
    if (_pControls[A_KEY]) {
      _loc[0] -= 0.08f;
    }
    if (_pControls[W_KEY]) {
      _loc[1] += 0.08f;
    }
    if (_pControls[S_KEY]) {
      _loc[1] -= 0.08f;
    }
    if (_pControls[SPACEBAR]) {
      _loc[2] += 0.05f;
    }

    simd_float3 pos = {0, 0, 0};
    // simd_float3 pos = {_loc[0], _loc[1], _loc[2]};

    struct CameraData *pCameraData = [_pCameraDataBuffer contents];

    pCameraData->model =
        matrix_multiply(makeTranslate(pos), makeZRotate(_angle));

    int forward_held = _pControls[W_KEY];
    int left_held = _pControls[A_KEY];
    int backward_held = _pControls[S_KEY];
    int right_held = _pControls[D_KEY];
    int jump_held = 0;
    int crouch_held = 0;
    float delta_cursor_x = (float)(currentMouse.x - previousMouse.x);
    float delta_cursor_y = (float)(currentMouse.y - previousMouse.y);
    flythrough_camera_update(
        eye, look, up, view, delta_time_seconds, eye_speed,
        degrees_per_cursor_move, max_pitch_rotation_degrees, delta_cursor_x,
        delta_cursor_y, forward_held, left_held, backward_held, right_held,
        jump_held, crouch_held, 0);
    simd_float4x4 viewMatrix = {
        (simd_float4){view[0], view[1], view[2], view[3]},
        (simd_float4){view[4], view[5], view[6], view[7]},
        (simd_float4){view[8], view[9], view[10], view[11]},
        (simd_float4){view[12], view[13], view[14], view[15]}};
    pCameraData->view = viewMatrix;
    previousMouse = currentMouse;

    pCameraData->perspective =
        makePerspective(45.f * M_PI / 180.f, 1.f, 0.03f, 500.0f);

    pCameraData->normalModel = chopMat(pCameraData->model);
    pCameraData->normalView = chopMat(pCameraData->view);

    // Encode render commands into CommandBuffer then commit

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