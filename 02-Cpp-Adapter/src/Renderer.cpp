#define NS_PRIVATE_IMPLEMENTATION
#define MTL_PRIVATE_IMPLEMENTATION
#define MTK_PRIVATE_IMPLEMENTATION
#define CA_PRIVATE_IMPLEMENTATION

#include <cassert>
#include <simd/simd.h>
#include "Renderer.hpp"

Renderer::Renderer(MTL::Device *const pDevice)
: _pDevice(pDevice)
, _pCommandQueue(_pDevice->newCommandQueue())
{
    buildShaders();
    buildBuffers();
}

Renderer::~Renderer()
{
    _pCommandQueue->release();
    _pPSO->release();
    _pDevice->release();
    _pVertexBuffer->release();
}

void Renderer::buildShaders() 
{
    const char* shader = R"(
        #include <metal_stdlib>
        using namespace metal;

        struct v2f
        {
            float4 position [[position]];
        };

        v2f vertex vertexMain(device const float3 *positions [[buffer(0)]],
                              uint vertexId [[vertex_id]])
        {
            v2f o;
            o.position = float4(positions[vertexId], 1.0);
            return o;
        }

        half4 fragment fragmentMain(v2f in [[stage_in]])
        {
            return (0.0, 0.0, 0.0, 0.0);
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
    const size_t numVertices = 3;

    simd::float3 positions[numVertices] = 
    {
        { -0.8f,  0.8f, 0.0f },
        {  0.0f, -0.8f, 0.0f },
        { +0.8f,  0.8f, 0.0f }
    };

    const size_t positionsSize = numVertices * sizeof(simd::float3);
    MTL::Buffer* pVertexBuffer = _pDevice->newBuffer(positionsSize, MTL::ResourceStorageModeManaged);
    _pVertexBuffer = pVertexBuffer;
    memcpy(_pVertexBuffer->contents(), positions, positionsSize);
    // _pVertexBuffer->didModifyRange(NS::Range::Make(0, _pVertexBuffer->length()));
}

void Renderer::draw(MTK::View* pView) const
{
    NS::AutoreleasePool* pPool = NS::AutoreleasePool::alloc()->init();

    MTL::CommandBuffer *pCmd = _pCommandQueue->commandBuffer();
    MTL::RenderPassDescriptor *pRpd = pView->currentRenderPassDescriptor();
    MTL::RenderCommandEncoder *pEnc = pCmd->renderCommandEncoder(pRpd);

    pEnc->setRenderPipelineState(_pPSO);
    pEnc->setVertexBuffer(_pVertexBuffer, 0, 0);
    pEnc->drawPrimitives(MTL::PrimitiveType::PrimitiveTypeTriangle,
                         NS::UInteger(0),
                         NS::UInteger(3));

    pEnc->endEncoding();
    pCmd->presentDrawable(pView->currentDrawable());
    pCmd->commit();
    
    pPool->release();
}
