# Cpp Adapter
Connect Objective C application codes with Cpp Metal rendering codes.

## Description
The MTKViewDelegate drawInMTKView method calls the AppAdapter draw method.

```objective-c
- (void)drawInMTKView:(MTKView *)view 
{
    [_pAppAdapter draw:view];
}
```

The AppAdapter draw method passes the MTKView casted to MTK::View to its Renderers draw method

```objective-c
@implementation AppAdapter

- (instancetype)initWithDevice:(id<MTLDevice>)device
{
    _pRenderer = new Renderer((__bridge MTL::Device *)device);
    return self;
}

- (void)draw:(MTKView*)view;
{
    _pRenderer->draw((__bridge MTK::View *)view);
}
```

The device is passed so the Renderer can create MTLCommandBuffers. With __bridge there is no transfer of ownership when casting to metal-cpp. Finally the Renderer draw method renders in the view, similar to the way it is done in 00-Learn-Metal-Cpp

```cpp
Renderer::Renderer(MTL::Device *const pDevice)
: _pDevice(pDevice)
, _pCommandQueue(_pDevice->newCommandQueue())
{}

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
```

## Todo: 
- Change .m files. Only AppAdapter.mm?

## Source
- Used as a starting point. However, there are a few differences. No storyboard or Xcode build, app delegate functions, cpp Renderer is only initialized with MTLDevice and its draw method takes MTKView as input.
    - https://github.com/DataDrivenEngineer/metal-videos
    - https://www.youtube.com/watch?v=oMdt5zWXUto
