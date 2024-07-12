#define NS_PRIVATE_IMPLEMENTATION
#define MTL_PRIVATE_IMPLEMENTATION
#define MTK_PRIVATE_IMPLEMENTATION
#define CA_PRIVATE_IMPLEMENTATION

#include "Renderer.hpp"
#include <iostream>

Renderer::Renderer(MTL::Device *const pDevice)
: _pDevice(pDevice)
, _pCommandQueue(_pDevice->newCommandQueue())
{}

Renderer::~Renderer()
{
    _pCommandQueue->release();
}

void Renderer::draw(MTK::View* pView) const
{
    NS::AutoreleasePool* pPool = NS::AutoreleasePool::alloc()->init();

    MTL::CommandBuffer *pCmd = _pCommandQueue->commandBuffer();
    MTL::RenderPassDescriptor *pRpd = pView->currentRenderPassDescriptor();
    MTL::RenderCommandEncoder *pEnc = pCmd->renderCommandEncoder(pRpd);
    pEnc->endEncoding();
    pCmd->presentDrawable(pView->currentDrawable());
    pCmd->commit();
    
    pPool->release();
}
