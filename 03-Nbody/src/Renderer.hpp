#include "Metal/Metal.hpp"
#include "MetalKit/MetalKit.hpp"
#include "Foundation/Foundation.hpp"
#include "QuartzCore/CAMetalDrawable.hpp"
#include <simd/simd.h>

class Renderer 
{
    public:
        Renderer(MTL::Device* pDevice);
        ~Renderer();
        void buildShaders();
        void buildBuffers();
        void draw(MTK::View* pView);
    private:
        MTL::Device* _pDevice;
        MTL::CommandQueue* const _pCommandQueue;
        MTL::RenderPipelineState* _pPSO;
        MTL::Buffer* _pVertexBuffer;
        MTL::Buffer* _pIndexBuffer;
        MTL::Buffer* _pInstanceBuffer;
        MTL::Buffer* _pCameraBuffer;
        float _time;
};

struct InstanceData
{
    simd::float4x4 transform;
    simd::float4 color;
};

struct CameraData
{
    simd::float4x4 world;
    simd::float4x4 perspective;
};