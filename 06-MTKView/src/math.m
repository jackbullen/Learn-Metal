#import "math.h"

simd_float3 add(const simd_float3 a, const simd_float3 b) {
  return (simd_float3){a.x + b.x, a.y + b.y, a.z + b.z};
}

simd_float4x4 makeIdentity() {
  return (simd_float4x4){
      (simd_float4){1.f, 0.f, 0.f, 0.f}, (simd_float4){0.f, 1.f, 0.f, 0.f},
      (simd_float4){0.f, 0.f, 1.f, 0.f}, (simd_float4){0.f, 0.f, 0.f, 1.f}};
}

simd_float4x4 makePerspective(float fovRadians, float aspect, float znear,
                              float zfar) {
  float ys = 1.f / tanf(fovRadians * 0.5f);
  float xs = ys / aspect;
  float zs = zfar / (znear - zfar);
  return simd_matrix_from_rows(
      (simd_float4){xs, 0.0f, 0.0f, 0.0f}, (simd_float4){0.0f, ys, 0.0f, 0.0f},
      (simd_float4){0.0f, 0.0f, zs, znear * zs}, (simd_float4){0, 0, -1, 0});
}

simd_float4x4 makeXRotate(float angleRadians) {
  const float a = angleRadians;
  return simd_matrix_from_rows((simd_float4){1.0f, 0.0f, 0.0f, 0.0f},
                               (simd_float4){0.0f, cosf(a), sinf(a), 0.0f},
                               (simd_float4){0.0f, -sinf(a), cosf(a), 0.0f},
                               (simd_float4){0.0f, 0.0f, 0.0f, 1.0f});
}

simd_float4x4 makeYRotate(float angleRadians) {
  const float a = angleRadians;
  return simd_matrix_from_rows((simd_float4){cosf(a), 0.0f, sinf(a), 0.0f},
                               (simd_float4){0.0f, 1.0f, 0.0f, 0.0f},
                               (simd_float4){-sinf(a), 0.0f, cosf(a), 0.0f},
                               (simd_float4){0.0f, 0.0f, 0.0f, 1.0f});
}

simd_float4x4 makeZRotate(float angleRadians) {
  const float a = angleRadians;
  return simd_matrix_from_rows((simd_float4){cosf(a), sinf(a), 0.0f, 0.0f},
                               (simd_float4){-sinf(a), cosf(a), 0.0f, 0.0f},
                               (simd_float4){0.0f, 0.0f, 1.0f, 0.0f},
                               (simd_float4){0.0f, 0.0f, 0.0f, 1.0f});
}

simd_float4x4 makeTranslate(const simd_float3 v) {
  const simd_float4 col0 = {1.0f, 0.0f, 0.0f, 0.0f};
  const simd_float4 col1 = {0.0f, 1.0f, 0.0f, 0.0f};
  const simd_float4 col2 = {0.0f, 0.0f, 1.0f, 0.0f};
  const simd_float4 col3 = {v.x, v.y, v.z, 1.0f};
  return simd_matrix(col0, col1, col2, col3);
}

simd_float4x4 makeScale(const simd_float3 v) {
  return simd_matrix((simd_float4){v.x, 0, 0, 0}, (simd_float4){0, v.y, 0, 0},
                     (simd_float4){0, 0, v.z, 0}, (simd_float4){0, 0, 0, 1.0});
}

simd_float3x3 chopMat(const simd_float4x4 mat) {
  return simd_matrix(mat.columns[0].xyz, mat.columns[1].xyz,
                     mat.columns[2].xyz);
}