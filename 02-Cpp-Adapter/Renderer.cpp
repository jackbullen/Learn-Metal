#define NS_PRIVATE_IMPLEMENTATION
#define MTL_PRIVATE_IMPLEMENTATION
// #define MTK_PRIVATE_IMPLEMENTATION
#define CA_PRIVATE_IMPLEMENTATION

#include "Renderer.hpp"
#include <iostream>

Renderer::Renderer(CA::MetalDrawable *const pDrawable, MTL::Device *const pDevice)
: _pDrawable(pDrawable)
, _pDevice(pDevice)
, _pCommandQueue(_pDevice->newCommandQueue())
{}

Renderer::~Renderer()
{
    _pCommandQueue->release();
}

void Renderer::draw() const
{
    std::cout << "draw call" << std::endl;
}
