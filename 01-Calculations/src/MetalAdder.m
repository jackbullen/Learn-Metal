#import "MetalAdder.h"
#include <Foundation/Foundation.h>
#include <Metal/Metal.h>

@implementation MetalAdder {
  id<MTLDevice> _pDevice;
  id<MTLComputePipelineState> _pCPSO;
  id<MTLCommandQueue> _pCommandQueue;
  id<MTLBuffer> _pArray1Buffer;
  id<MTLBuffer> _pArray2Buffer;
  id<MTLBuffer> _pResultBuffer;
  int _arrayLength;
}

- (instancetype)initWithDevice:(id<MTLDevice>)device {
  self = [super init];
  if (self) {
    _pDevice = device;

    NSError *error = nil;
    // id<MTLLibrary> library = [_pDevice newDefaultLibrary];
    NSURL* URL = [NSURL URLWithString:@"./bin/add.metallib"];
    id<MTLLibrary> library = [_pDevice newLibraryWithURL:URL error:&error];
    if (!library) {
      NSLog(@"Failed to initialize library: %@", [error localizedDescription]);
      assert(false);
    }

    id<MTLFunction> computeFn = [library newFunctionWithName:@"add"];
    if (!computeFn) {
      NSLog(@"Failed to create compute function \"add\"\n");
      assert(false);
    }

    _pCPSO = [_pDevice newComputePipelineStateWithFunction:computeFn
                                                     error:&error];
    if (!_pCPSO) {
      NSLog(@"Failed to create pipeline state\n");
      assert(false);
    }

    _pCommandQueue = [_pDevice newCommandQueue];
    if (!_pCommandQueue) {
      NSLog(@"Failed to create command queue\n");
      assert(false);
    }
  }
  return self;
}

- (void)prepareBuffers:(float *)arr1 :(float *)arr2 :(int)arrayLength {
  _pArray1Buffer = [_pDevice newBufferWithBytes:arr1 
                                length:arrayLength * sizeof(float) 
                                    options:MTLResourceStorageModeShared];
  _pArray2Buffer = [_pDevice newBufferWithBytes:arr2 
                                length:arrayLength * sizeof(float) 
                                    options:MTLResourceStorageModeShared];
  _pResultBuffer = [_pDevice newBufferWithLength:arrayLength * sizeof(float) 
                                options:MTLResourceStorageModeShared];
  _arrayLength = arrayLength;
}

- (void)compute {
  id<MTLCommandBuffer> pCmd = [_pCommandQueue commandBuffer];
  assert(pCmd != nil);
  id<MTLComputeCommandEncoder> pCEnc = [pCmd computeCommandEncoder];
  assert(pCEnc != nil);

  [self addEncoding:pCEnc];
  [pCEnc endEncoding];
  [pCmd commit];

  [pCmd waitUntilCompleted];

  float* a = _pArray1Buffer.contents;
  float* b = _pArray2Buffer.contents;
  float* c = _pResultBuffer.contents;

  for (int i = 0; i < _arrayLength; i++)
  {
    printf("%2.0f ?= %2.0f\n", a[i]+b[i], c[i]);
  }
}

- (void)addEncoding:(id<MTLComputeCommandEncoder>)pCEnc {
  [pCEnc setComputePipelineState:_pCPSO];
  [pCEnc setBuffer:_pArray1Buffer offset:0 atIndex:0];
  [pCEnc setBuffer:_pArray2Buffer offset:0 atIndex:1];
  [pCEnc setBuffer:_pResultBuffer offset:0 atIndex:2];

  MTLSize gridSize = MTLSizeMake(_arrayLength, 1, 1);
  NSUInteger threadGroupSize = _pCPSO.maxTotalThreadsPerThreadgroup;
  if (threadGroupSize > _arrayLength) {
    threadGroupSize = _arrayLength;
  }
  MTLSize threadgroupSize = MTLSizeMake(threadGroupSize, 1, 1);
  [pCEnc dispatchThreads:gridSize threadsPerThreadgroup:threadgroupSize];
}

@end