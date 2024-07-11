#include <metal_stdlib>
using namespace metal;

// MTL version
kernel void add(device const float* inA,
                device const float* inB,
                device float* result,
                uint index [[thread_position_in_grid]])
{
    result[index] = inA[index] + inB[index];
}
