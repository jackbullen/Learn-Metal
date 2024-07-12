#include "Metal/Metal.hpp"
#include "MetalKit/MetalKit.hpp"
#include "Foundation/Foundation.hpp"
#include "QuartzCore/CAMetalDrawable.hpp"

class Renderer 
{
    public:
        Renderer(MTK::View *const pView, MTL::Device *const pDevice);
        ~Renderer();
        void draw() const;
    private:
        MTK::View *_pView;
        MTL::Device *const _pDevice;
        MTL::CommandQueue *const _pCommandQueue;
};