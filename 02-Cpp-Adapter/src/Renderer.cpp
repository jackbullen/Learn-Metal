#define NS_PRIVATE_IMPLEMENTATION
#define MTL_PRIVATE_IMPLEMENTATION
#define MTK_PRIVATE_IMPLEMENTATION
#define CA_PRIVATE_IMPLEMENTATION

#include "Renderer.hpp"
#include <iostream>

Renderer::Renderer(MTK::View *const pView, MTL::Device *const pDevice)
: _pView(pView)
, _pDevice(pDevice)
, _pCommandQueue(_pDevice->newCommandQueue())
{}

Renderer::~Renderer()
{
    _pCommandQueue->release();
}

void Renderer::draw() const
{
    NS::AutoreleasePool* pPool = NS::AutoreleasePool::alloc()->init();

    MTL::CommandBuffer *pCmd = _pCommandQueue->commandBuffer();
    MTL::RenderPassDescriptor *pRpd = _pView->currentRenderPassDescriptor();
    MTL::RenderCommandEncoder *pEnc = pCmd->renderCommandEncoder(pRpd);
    pEnc->endEncoding();
    pCmd->presentDrawable(_pView->currentDrawable());
    pCmd->commit();
    
    pPool->release();
}
