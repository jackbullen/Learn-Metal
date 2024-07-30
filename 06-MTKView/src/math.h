#import <simd/simd.h>

simd_float3 add(const simd_float3 a, const simd_float3 b);
simd_float4x4 makeIdentity();
simd_float4x4 makePerspective(float fovRadians, float aspect, float znear, float zfar);
simd_float4x4 makeXRotate(float angleRadians);
simd_float4x4 makeYRotate(float angleRadians);
simd_float4x4 makeZRotate(float angleRadians);
simd_float4x4 makeTranslate(const simd_float3 v);
simd_float4x4 makeScale(const simd_float3 v);
simd_float3x3 chopMat(const simd_float4x4 mat);
