#include <Foundation/Foundation.h>
#include <Metal/Metal.h>
#import "MetalAdder.h"

@implementation MetalAdder 
{
  id<MTLDevice> _pDevice;
  id<MTLComputePipelineState> _pAddPSO;
  id<MTLCommandQueue> _pCommandQueue;
  id<MTLBuffer> _pArray1Buffer;
  id<MTLBuffer> _pArray2Buffer;
  id<MTLBuffer> _pResultBuffer;
  int _arrayLength;
}

// Store MTLDevice, MTLCommandQueue, MTLComputePipelineState,
// and MTLBuffers into instance variables
- (instancetype)initWithDevice:(id<MTLDevice>)device 
                  arrayLength:(int)arrayLength
{
  self = [super init];
  if (self) 
  {
    _pDevice = device;

    NSError *error = nil;

    _pCommandQueue = [_pDevice newCommandQueue];
    if (!_pCommandQueue) 
    {
      NSLog(@"Failed to create command queue\n");
      assert(false);
    }

    NSURL* URL = [NSURL URLWithString:@"./bin/add.metallib"];
    id<MTLLibrary> library = [_pDevice newLibraryWithURL:URL error:&error];
    if (!library) 
    {
      NSLog(@"Failed to initialize library: %@", [error localizedDescription]);
      assert(false);
    }

    id<MTLFunction> addFn = [library newFunctionWithName:@"add"];
    if (!addFn) 
    {
      NSLog(@"Failed to create add function \"add\"\n");
      assert(false);
    }

    _pAddPSO = [_pDevice newComputePipelineStateWithFunction:addFn error:&error];
    if (!_pAddPSO) 
    {
      NSLog(@"Failed to create add pipeline state\n");
      assert(false);
    }
    
    [self buildBuffers:arrayLength];
  }
  return self;
}

// Store MTLBuffer objects into instance variables
- (void)buildBuffers:(int)arrayLength 
{
  _pArray1Buffer = [_pDevice newBufferWithLength:arrayLength * sizeof(float) 
                                options:MTLResourceStorageModeManaged];
  _pArray2Buffer = [_pDevice newBufferWithLength:arrayLength * sizeof(float)
                                options:MTLResourceStorageModeManaged];
  _pResultBuffer = [_pDevice newBufferWithLength:arrayLength * sizeof(float) 
                                options:MTLResourceStorageModeManaged];
  _arrayLength = arrayLength;
}

// Update instance MTLBuffer objects with new data
- (void)updateBuffers:(float*)arr1 :(float*)arr2
{
  float* pArray1Buffer = _pArray1Buffer.contents;
  float* pArray2Buffer = _pArray2Buffer.contents;
  for (int i = 0; i < _arrayLength; i++)
  {
    pArray1Buffer[i] = arr1[i];
    pArray2Buffer[i] = arr2[i];
  }
  // [_pArray1Buffer didModifyRange:NSMakeRange(0, _pArray1Buffer.length)];
  // [_pArray1Buffer didModifyRange:NSMakeRange(0, _pArray2Buffer.length)];
}

// Commit a command buffer to MTLComputePipelineState
- (void)computePipeline:(id<MTLComputePipelineState>)pCPSO 
{
  id<MTLCommandBuffer> pCmd = [_pCommandQueue commandBuffer];
  assert(pCmd != nil);
  id<MTLComputeCommandEncoder> pCEnc = [pCmd computeCommandEncoder];
  assert(pCEnc != nil);

  [self addEncoding:pCEnc withPipeline:pCPSO];
  [pCEnc endEncoding];
  [pCmd commit];

  [pCmd waitUntilCompleted];
  // [_pResultBuffer didModifyRange:NSMakeRange(0, _pResultBuffer.length)];
}

// Set pipeline and buffers to encoder and encode compute commands
- (void)addEncoding:(id<MTLComputeCommandEncoder>)pCEnc 
          withPipeline:(id<MTLComputePipelineState>)pCPSO 
{
  [pCEnc setComputePipelineState:pCPSO];
  [pCEnc setBuffer:_pArray1Buffer offset:0 atIndex:0];
  [pCEnc setBuffer:_pArray2Buffer offset:0 atIndex:1];
  [pCEnc setBuffer:_pResultBuffer offset:0 atIndex:2];

  MTLSize gridSize = MTLSizeMake(_arrayLength, 1, 1);
  NSUInteger threadGroupSize = pCPSO.maxTotalThreadsPerThreadgroup;
  if (threadGroupSize > _arrayLength) 
  {
    threadGroupSize = _arrayLength;
  }
  MTLSize threadgroupSize = MTLSizeMake(threadGroupSize, 1, 1);
  [pCEnc dispatchThreads:gridSize threadsPerThreadgroup:threadgroupSize];
}

- (float*)add:(float*)arr1 to:(float*)arr2
{
  [self updateBuffers:arr1 :arr2];
  [self computePipeline:_pAddPSO];
  return _pResultBuffer.contents;
}

- (void)display
{
  float* a = _pArray1Buffer.contents;
  float* b = _pArray2Buffer.contents;
  float* c = _pResultBuffer.contents;

  for (int i = 0; i < _arrayLength; i++)
  {
      printf("%2.0f ?= %2.0f\n", a[i]+b[i], c[i]);
  }
}

@end