#include <metal_stdlib>
using namespace metal;

struct v2f 
{
    float4 position [[position]];
    float3 normal;
    half4 color;
    float2 texcoord;
};

struct VertexData
{
    float3 position;
    float3 normal;
    float2 texcoord;
};

struct CameraData
{
    float4x4 model;
    float4x4 view;
    float4x4 perspective;
    float3x3 normalTransform;
    float3x3 normalView;
};

v2f vertex vertexMain(device const VertexData* vertexData [[buffer(0)]],
                      device const CameraData& cameraData [[buffer(1)]],
                      uint vid [[vertex_id]])
{
    v2f o;

    // Get the current vertex
    const device VertexData& vd = vertexData[vid];

    // Apply transformations to position
    float4 pos = float4(vd.position, 1.0);

    // 1. Model Transformation
    pos = cameraData.model * pos;

    // 2. View Transformation
    pos = cameraData.view * pos;
    
    // 3. Perspective Transformation
    pos = cameraData.perspective * pos;

    // Apply transformations to normal
    float3 normal = vd.normal;
    normal = cameraData.normalTransform * normal;
    normal = cameraData.normalView * normal;

    o.position = pos;
    o.normal = normal;
    o.texcoord = vd.texcoord;
    o.color = half4(1.0, 1.0, 1.0, 1.0);
    return o;
}

half4 fragment fragmentMain(v2f in [[stage_in]])
{
    float3 lightD = normalize(float3(0.0, 0.0, -1.0));
    float3 normal = normalize(in.normal);

    half3 illumin = in.color.rgb * saturate(dot(lightD, normal));
    return half4(illumin, in.color.a);
}
