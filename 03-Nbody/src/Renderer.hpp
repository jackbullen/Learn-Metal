#include "Metal/Metal.hpp"
#include "MetalKit/MetalKit.hpp"
#include "Foundation/Foundation.hpp"
#include "QuartzCore/CAMetalDrawable.hpp"

class Renderer 
{
    public:
        Renderer(MTL::Device *const pDevice);
        ~Renderer();
        void buildShaders();
        void buildBuffers();
        void draw(MTK::View *const pView) const;
    private:
        MTL::Device *const _pDevice;
        MTL::CommandQueue *const _pCommandQueue;
        MTL::RenderPipelineState* _pPSO;
        MTL::Buffer* _pVertexBuffer;
};