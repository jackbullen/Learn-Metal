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
    float4x4 transform;
    float3x3 normalTransform;
    float4x4 perspective;
    float4x4 world;
    float3x3 worldNormal;
};

v2f vertex vertexMain(device const VertexData* vertexData [[buffer(0)]],
                      device const CameraData& cameraData [[buffer(1)]],
                      uint vid [[vertex_id]])
{
    v2f o;

    const device VertexData& vd = vertexData[vid];
    float4 pos = float4(vd.position, 1.0);
    pos = cameraData.transform * pos;
    pos = cameraData.perspective * cameraData.world * pos;
    o.position = pos;

    float3 normal = cameraData.normalTransform * vd.normal;
    normal = cameraData.worldNormal * normal;
    o.normal = normal;

    o.texcoord = vd.texcoord;

    o.color = half4(1.0, 1.0, 1.0, 1.0);
    return o;
}

half4 fragment fragmentMain(v2f in [[stage_in]],
                            texture2d<half, access::sample> tex [[texture(0)]])
{
    constexpr sampler s(address::repeat, filter::linear);
    half3 texel = tex.sample(s, in.texcoord).rgb;

    float3 lightD = normalize(float3(0.0, 0.0, 1.0));
    float3 normal = normalize(in.normal);

    half3 illumin = in.color.rgb * texel * saturate(dot(lightD, normal));
    return half4(illumin, in.color.a);
}