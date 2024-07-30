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
- (void)draw:(MTKView *)view;
@end

struct VertexData {
  simd_float3 position;
  simd_float3 normal;
  simd_float2 texcoord;
};

struct CameraData {
  simd_float4x4 transform;
  simd_float3x3 normalTransform;
  simd_float4x4 perspective;
  simd_float4x4 world;
  simd_float3x3 worldNormal;
};