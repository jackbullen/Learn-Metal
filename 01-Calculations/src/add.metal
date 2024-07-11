#include <metal_stdlib>
using namespace metal;

// MTL version
kernel void add(device const float* arr1,
                device const float* arr2,
                device float* result,
                uint i [[thread_position_in_grid]])
{
    result[i] = arr1[i] + arr2[i];
}
