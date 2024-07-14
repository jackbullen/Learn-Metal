#define NS_PRIVATE_IMPLEMENTATION
#define MTL_PRIVATE_IMPLEMENTATION
#define MTK_PRIVATE_IMPLEMENTATION
#define CA_PRIVATE_IMPLEMENTATION

#include <cassert>
#include <simd/simd.h>
#include "Renderer.hpp"
#include "math.h"

static constexpr size_t numInstances = 32;

Renderer::Renderer(MTL::Device *const pDevice)
: _pDevice(pDevice)
, _pCommandQueue(_pDevice->newCommandQueue())
{
    _time = 0;
    buildShaders();
    buildBuffers();
}

Renderer::~Renderer()
{
    _pCommandQueue->release();
    _pPSO->release();
    _pDevice->release();
    _pVertexBuffer->release();
    _pIndexBuffer->release();
    _pInstanceBuffer->release();
    _pCameraBuffer->release();
}

void Renderer::buildShaders() 
{
    const char* shader = R"(
        #include <metal_stdlib>
        using namespace metal;

        struct v2f
        {
            float4 position [[position]];
            half3 color;
        };

        struct VertexData
        {
            float3 position;
        };

        struct InstanceData
        {
            float4x4 transform;
            float4 color;
        };

        struct CameraData
        {
            float4x4 perspective;
            float4x4 world;
        };

        v2f vertex vertexMain(device const VertexData* vertexData [[buffer(0)]],
                              device const InstanceData* instanceData [[buffer(1)]],
                              device const CameraData& cameraData [[buffer(2)]],
                              uint vertexId [[vertex_id]],
                              uint instanceId [[instance_id]])
        {
            v2f o;
            float4 pos = float4(vertexData[vertexId].position, 1.0);
            pos = instanceData[instanceId].transform * pos;
            pos = cameraData.perspective * cameraData.world * pos;
            o.position = pos;
            o.color = half3(instanceData[instanceId].color.rgb);
            return o;
        }

        half4 fragment fragmentMain(v2f in [[stage_in]])
        {
            return (in.color, 0.0);
        }
    )";

    NS::Error* error = nullptr;
    MTL::Library* pLibrary = _pDevice->newLibrary(NS::String::string(shader, NS::StringEncoding::UTF8StringEncoding), nullptr, &error);
    if ( !pLibrary )
    {
        __builtin_printf( "%s", error->localizedDescription()->utf8String() );
        assert( false );
    }

    MTL::Function* pVertexFn = pLibrary->newFunction(NS::String::string("vertexMain", NS::StringEncoding::UTF8StringEncoding));
    MTL::Function* pFragmentFn = pLibrary->newFunction(NS::String::string("fragmentMain", NS::StringEncoding::UTF8StringEncoding));

    MTL::RenderPipelineDescriptor* pDesc = MTL::RenderPipelineDescriptor::alloc()->init();
    pDesc->setVertexFunction(pVertexFn);
    pDesc->setFragmentFunction(pFragmentFn);
    pDesc->colorAttachments()->object(0)->setPixelFormat(MTL::PixelFormat::PixelFormatBGRA8Unorm_sRGB);

    _pPSO = _pDevice->newRenderPipelineState(pDesc, &error);
    if (!_pPSO)
    {
        __builtin_printf("%s", error->localizedDescription()->utf8String());
        assert(false);
    }

    pVertexFn->release();
    pFragmentFn->release();
    pDesc->release();
    pLibrary->release();
}

void Renderer::buildBuffers()
{
    const float s = 0.5f;

    simd::float3 vertices[] = 
    {
        { -s, -s, +s },
        { +s, -s, +s },
        { +s, +s, +s },
        { -s, +s, +s },

        { -s, -s, -s },
        { -s, +s, -s },
        { +s, +s, -s },
        { +s, -s, -s }
    };

    uint16_t indices[] = {
        0, 1, 2, /* front */
        2, 3, 0,

        1, 7, 6, /* right */
        6, 2, 1,

        7, 4, 5, /* back */
        5, 6, 7,

        4, 0, 3, /* left */
        3, 5, 4,

        3, 2, 6, /* top */
        6, 5, 3,

        4, 7, 1, /* bottom */
        1, 0, 4
    };

    const size_t verticesSize = sizeof(vertices);
    const size_t indicesSize = sizeof(indices);
    MTL::Buffer* pVertexBuffer = _pDevice->newBuffer(verticesSize, MTL::ResourceStorageModeManaged);
    MTL::Buffer* pIndexBuffer = _pDevice->newBuffer(indicesSize, MTL::ResourceStorageModeManaged);
    _pVertexBuffer = pVertexBuffer;
    _pIndexBuffer = pIndexBuffer;
    memcpy(_pVertexBuffer->contents(), vertices, verticesSize);
    memcpy(_pIndexBuffer->contents(), indices, indicesSize);
    _pVertexBuffer->didModifyRange(NS::Range::Make(0, _pVertexBuffer->length()));
    _pIndexBuffer->didModifyRange(NS::Range::Make(0, _pIndexBuffer->length()));

    const size_t instanceSize = numInstances * sizeof(InstanceData);
    MTL::Buffer* pInstanceBuffer = _pDevice->newBuffer(instanceSize, MTL::ResourceStorageModeManaged);
    _pInstanceBuffer = pInstanceBuffer;

    const size_t cameraSize = sizeof(CameraData);
    MTL::Buffer* pCameraBuffer = _pDevice->newBuffer(cameraSize, MTL::ResourceStorageModeManaged);
    _pCameraBuffer = pCameraBuffer;
}

void Renderer::draw(MTK::View* pView)
{
    NS::AutoreleasePool* pPool = NS::AutoreleasePool::alloc()->init();
    
    MTL::CommandBuffer *pCmd = _pCommandQueue->commandBuffer();

    _time += 0.01f;

    const float scl = 1.f;
    InstanceData* pInstanceData = reinterpret_cast<InstanceData*>(_pInstanceBuffer->contents());

    simd::float3 objectPosition = {0.f, 0.f, -5.f};
    simd::float4x4 objectTransform = math::makeTranslate(objectPosition);
    simd::float4x4 scale = math::makeScale({scl, scl, scl});
    for (size_t i = 0; i < numInstances; i++)
    {
        pInstanceData[i].transform = objectTransform * scale;
        pInstanceData[i].color = (simd::float4){0.0, 0.0, 0.0, 0.0};
    }
    _pInstanceBuffer->didModifyRange( NS::Range::Make( 0, _pInstanceBuffer->length() ) );

    CameraData* pCameraData = reinterpret_cast<CameraData*>(_pCameraBuffer->contents());
    pCameraData->perspective = math::makePerspective(45.f * M_PI / 180.f, 1.f, 0.03f, 500.f);
    pCameraData->world = math::makeIdentity();
    _pCameraBuffer->didModifyRange( NS::Range::Make( 0, sizeof( CameraData ) ) );

    MTL::RenderPassDescriptor *pRpd = pView->currentRenderPassDescriptor();
    MTL::RenderCommandEncoder *pEnc = pCmd->renderCommandEncoder(pRpd);

    pEnc->setRenderPipelineState(_pPSO);
    
    pEnc->setVertexBuffer(_pVertexBuffer, 0, 0);
    pEnc->setVertexBuffer(_pInstanceBuffer, 0, 1);
    pEnc->setVertexBuffer(_pCameraBuffer, 0, 2);

    pEnc->drawIndexedPrimitives(MTL::PrimitiveTypeTriangle,
                                36,
                                MTL::IndexType::IndexTypeUInt16,
                                _pIndexBuffer,
                                0,
                                numInstances);

    pEnc->endEncoding();
    pCmd->presentDrawable(pView->currentDrawable());
    pCmd->commit();
    
    pPool->release();
}
