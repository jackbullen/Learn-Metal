#include "math.h"
#import <AppKit/AppKit.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import <simd/simd.h>

@interface Renderer : NSObject
- (instancetype)initWithDevice:(id<MTLDevice>)device;
- (void)buildShaders;
- (void)buildDepthStencilState;
- (void)buildTextures;
- (void)buildBuffers;

- (void)keyUpEvent:(NSEvent *)event;
- (void)keyDownEvent:(NSEvent *)event;
- (void)mouseDownEvent:(NSPoint *)event;
- (void)mouseUpEvent:(NSPoint *)event;
- (void)mouseDraggedEvent:(NSPoint *)event;

- (void)draw:(MTKView *)view;
@end

struct VertexData {
  simd_float3 position;
  simd_float3 normal;
  simd_float2 texcoord;
};

struct CameraData {
  simd_float4x4 model;
  simd_float4x4 view;
  simd_float4x4 perspective;
  simd_float3x3 normalModel;
  simd_float3x3 normalView;
};