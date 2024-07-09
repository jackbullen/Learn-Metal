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

struct InstanceData 
{ 
    float4x4 instanceTransform; 
    float3x3 instanceNormalTransform; 
    float4 instanceColor; 
}; 

struct CameraData 
{ 
    float4x4 perspectiveTransform; 
    float4x4 worldTransform; 
    float3x3 worldNormalTransform; 
}; 

v2f vertex vertexMain(device const VertexData* vertexData [[buffer(0)]], 
                      device const InstanceData* instanceData [[buffer(1)]], 
                      device const CameraData& cameraData [[buffer(2)]], 
                      uint vertexId [[vertex_id]], 
                      uint instanceId [[instance_id]]) 
{ 
    v2f o; 
    
    const device VertexData& vd = vertexData[vertexId]; 
    const device InstanceData& id = instanceData[instanceId]; 
    float4 pos = float4(vd.position, 1.0); 
    pos = id.instanceTransform * pos; 
    pos = cameraData.perspectiveTransform * cameraData.worldTransform * pos; 
    o.position = pos; 
    
    float3 normal = id.instanceNormalTransform * vd.normal; 
    normal = cameraData.worldNormalTransform * normal; 
    o.normal = normal; 

    o.texcoord = vd.texcoord;

    o.color = half4(id.instanceColor); 
    return o; 
} 

half4 fragment fragmentMain(v2f in [[stage_in]],
                            texture2d<half, access::sample> tex [[texture(0)]]) 
{ 
    constexpr sampler s(address::repeat, filter::linear);
    half3 texel = tex.sample(s, in.texcoord).rgb;

    float3 lightD = normalize(float3(1.0, 1.0, 0.8)); 
    float3 normal = normalize(in.normal); 

    half3 illumin = in.color.rgb * texel * saturate(dot(lightD, normal));
    return half4(illumin, in.color.a); 
} 