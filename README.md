# Learning Metal

## Overview

* 00 - window : Create a Window for Metal Rendering
* 01 - primitive : Render a Triangle
* 02 - argbuffers : Store Shader Arguments in a Buffer
* 03 - animation : Animate Rendering
* 04 - instancing : Draw Multiple Instance of an Object
* 05 - perspective : Render 3D with Perspective Projection

--- 

* 06 - lighting : Light Geometry
* 07 - texturing : Texture Triangles
* 08 - compute : Use the GPU for General Purpose Computation
* 09 - compute-to-render : Render the Results of a Compute Kernel
* 10 - frame-debugging : Capture GPU Commands for Debugging

## Dependencies

- cpp: 
    - metal-cpp (Foundation, Metal, QuartzCore)
    - metal-cpp-extensions (AppKit, MetalKit)

- objc: 
    - Metal
    - MetalKit
    - AppKit
    
## Sample 0: Create a Window for Metal Rendering

The `00-window` sample shows how to create a macOS application with a window capable of displaying content drawn using Metal. This sample clears the contents of the window to a solid red color.

In order to create the window, the app obtains the global shared application object and sets a custom application delegate (subclass of `ApplicationDelegate`). 

The delegate receives notifications of system events and responds when the application has finished launching and is ready to create its window. The notification of this event arrives in the `applicationDidFinishLaunching` method. The sample overrides this method and creates the window, a menu, and the Metal-capable content view, an `MTKView`. `MTKView` displays Metal content in a window. `MTKView` also provides a runtime loop that triggers rendering at a regular cadence. 

The `applicationDidFinishLaunching` method initializes the view with a `CGRect` describing its dimensions and a `MTLDevice` object, a software representation of the system's GPU. This method also specifies a pixel format for the view's drawable render target and sets a color with which to clear the drawable each frame.

The method also sets an instance of the `MyMTKViewDelegate` class as a delegate.

`MyMTKViewDelegate` is a subclass of the `MTKViewDelegate`, which provides an interface to `MTKView` for event forwarding. By overriding the virtual functions of its parent class, `MyMTKViewDelegate` can respond to these events. `MTKView` calls the `drawInMTKView` method each frame allowing the app to update any rendering.

`drawInMTKView` simply calls the `Renderer` class's `draw` method.  The `draw` method performs the minimal work necessary to clear the view's color.

It performs the following actions:

1. Create CommandBuffer.  This allows the app to encode commands for execution by the GPU.
2. Create RenderCommandEncoder.  This prepares the command buffer to receive drawing commands and specifies the actions to perform when drawing starts and ends.
3. Present the drawable. This encodes a command to make the results of the GPU’s work visible on the screen.
4. Submit the encoded commands to the GPU for execution.

In this sample, the `MTLRenderCommandEncoder` object does not explicitly encode any commands. However, the `MTLRenderPassDescriptor` implicitly encodes a clear command.

Metal relies on temporary *autoreleased* objects.

## Sample 1: Render a Triangle

The `01-Primitive` draws a triangle.

Before issuing a draw command, the renderer must describe the configuration of a *render pipeline*. The renderer uses an `MTLRenderPipelineState` to define how the GPU should process the geometry drawn.

Metal uses MSL (C++ 14 derivative) to specify the vertex and fragment shaders. Typically Xcode would compile these, however, this sample has shader source in string. Renderer creates a `MTLLibrary` with the string.

This builds an intermediate representation of the shader code. Then the renderer obtains `MTLFunction` objects from the `MTLLibrary` by calling `newFunction` with the shader function names.

Next, the renderer creates an `MTLRenderPipelineDescriptor` to designate the two shaders the pipeline should use. It also specifies the pixel format used by `MTKView`.

With the descriptor object, the renderer uses the `MTLDevice` object to create a concrete `MTLRenderPipelineState` object via the `newRenderPipelineState` method.

`MTL::RenderPipelineState` objects are expensive to create since Metal must invoke a compiler to convert the shader to GPU machine code. It is a best practice to build a pipeline once, either during application start or at a point where users expect a load operation to occur.

The renderer also specifies a position and color for each vertex of the triangle. It stores this data in `MTLBuffer` objects.

Buffers are unstructured memory allocations accessible by the GPU. An app can interpret buffer data however it likes. In the sample, the renderer uses two buffers to pass vertex data to the vertex shader. The first buffer stores an array of three `sims::float3` vectors, which specify the 3D positions of the vertices. The second buffer also stores an array of three `simd::float3` vectors, which specify RGB color values for each vertex.

The renderer creates these buffers using `MTLResourceStorageModeManaged`. This indicates that the CPU and GPU may maintain seperate copies of the data, and any changes must be synchronized (`didModifyRange`).

Once the renderer creates the render pipeline and buffer objects, it can begin encoding commands to draw the triangle. This sample extends upon the previous sample's `draw` function by explicitly encoding commands to do this.

After the function creates the render command encoder, it calls the encoder's `setRenderPipelineState` method. It then sets the buffers' containing vertex positions and colors so that Metal passes them as arguments to the vertex shader.

In the vertex shader function, the `positions` and `colors`  parameters use the `[[buffer(0)]]` and `[[buffer(1)]]` attributes. The sample calls `setVertexBuffer` using the indices declared with these attributes to pass the buffers to these parameters.

```c++
v2f vertex vertexMain( uint vertexId [[vertex_id]],
                       device const float3* positions [[buffer(0)]],
                       device const float3* colors [[buffer(1)]] )
```

Once the `draw` method sets the vertex buffers, it encodes a draw command with a call to the encoder's `drawPrimitives` method. The `drawPrimitives` method draws a triangle using the render pipeline with the three vertices in the set buffers.

## Sample 2: Store Shader Arguments in a Buffer

`02-argbuffers` adds an *argument buffer* for the vertex data. Argument buffers are a buffer that can contain references other buffers.

The renderer creates an argument encoder for the parameter of the shader. It calls the `MTLFunction::newArgumentEncoder` method with the index of the buffer parameter to encode.

The encoder gets the parameter's memory requirements using the value returned from the `MTLArgumentEncoder::encodedLength` method.

The renderer then binds the argument buffer to the argument encoder via the `MTLArgumentEncoder::setArgumentBuffer` method. This specifies the destination to which the encoder writes the object references.

With the buffer objects created and set, the renderer encodes references to the position data in index `0` and to the color data in  index `1`.

```objective-c
[pArgEncoder setBuffer:_pVertexPositionsBuffer offset:0 atIndex:0];
[pArgEncoder setBuffer:_pVertexColorsBuffer offset:0 atIndex:1];
```

The indices input to `MTLArgumentEncoder::setBuffer` correspond to numbers used with the `[[id()]]` attribute specifier in the shader code.

```c++
struct VertexData
{
    device float3* positions [[id(0)]];
    device float3* colors [[id(1)]];
};
```

With the buffers ready, the renderer can begin encoding render commands. 

First, it makes the argument buffer available to the vertex shader.

```objective-c
[pEnc setVertexBuffer:_pArgBuffer offset:0 atIndex:0];
```

The renderer must call the `MTLArgumentEncoder::useResource` method because the shader indirectly references these vertex data buffers through the argument buffer. This indicates to Metal that the buffer needs to be present in memory when executing the command buffer.

```objective-c
[pEnc useResource:_pVertexPositionsBuffer usage:MTLResourceUsageRead];
[pEnc useResource:_pVertexColorsBuffer usage:MTLResourceUsageRead];
```

## Sample 3: Animate Rendering

`03-animation` adds an animation to spin the triangle.

A rotation angle is passed to the vertex shader and rotates the vertices.

``` c++
struct FrameData
{
    float angle;
};
```

Metal provides a convenient method to pass small amounts of data to shaders via the `MTLBuffer::setVertexBytes` method. The `FrameData` structure is small enough that the sample *could* use `setVertexBytes` to pass it to the vertex shader. However, passing larger amounts of data requires using `MTLBuffer` objects. To demonstrate passing a large amount of data, the sample passes the `FrameData` structure using a series of  Metal buffers.

```objective-c
for ( int i = 0; i < Renderer::kMaxFramesInFlight; ++i )
{
    _pFrameData[ i ]= [_pDevice newBufferWithLength:sizeof(FrameData) options:MTLResourceStorageModeManaged];
}
```

`_pFrameBuffer` stores three versions of the FrameData structure. The renderer uses multiple versions of these buffers to avoid a data race condition where the CPU writes a new value to the buffer while the GPU simultaneously reads from the buffer.  It cycles through three buffers which allows the CPU to update one buffer while GPU reads from another.

The renderer uses a *semaphore* to explicitly synchronize buffer updates. This ensures the CPU does not update a buffer the GPU is currently processing data from.

Upon initialization, the renderer creates the semaphore with a value of `kMaxFramesInFlight = 3`.

```objective-c
_semaphore = dispatch_semaphore_create( kMaxFramesInFlight );
```

At the beginning of each frame, the renderer calls `dispatch_semaphore_wait`. This forces to CPU to wait if the GPU has not finished reading from the current _frame buffer in the the cycle.

```objective-c
dispatch_semaphore_wait( _semaphore, DISPATCH_TIME_FOREVER );
```

The renderer receives a signal when the GPU has finished processing each command buffer via a *completed handler* closure.  

```objective-c
[pCmd addCompletedHandler:^(id<MTLCommandBuffer> buffer) {
    dispatch_semaphore_signal(_semaphore);
}];
```

Once the renderer has a buffer it can safely use, it overwrites the buffer’s contents with a new value. Because these are managed storage buffers, the sample must notify Metal of the content change.

```objective-c
((FrameData *)pFrameDataBuffer.contents)->angle = (_angle += 0.01f);
[pFrameDataBuffer didModifyRange:NSMakeRange(0, pFrameDataBuffer.length)];
```

## Sample 4: Draw Multiple Instances of an Object

`04-instancing` draws multiple primitives from a single draw command by transforming the same set of vertices to several positions, rendering the same object multiple times.

Issuing a draw call incurs some amount of overhead. Instancing reduces the number of calls required to render a scene.

The renderer provides each instance with a unique value for positions and colors.  The renderer's `buildBuffers` method creates a buffer that holds this data.

With these buffers filled with up-to-date instance data, the `draw()` method encodes rendering commands.

The renderer supplies the instance data to the vertex shader with a call to `MTLRenderCommandEncoder::setVertexBuffer`.  It then issues a draw call with `MTLRenderCommandEncoder::drawIndexPrimitives`.

Within the vertex shader, the sample determines what instance each vertex belongs to and retrieves the data specific to its instance.

```c++
v2f vertex vertexMain( device const VertexData* vertexData [[buffer(0)]],
                       device const InstanceData* instanceData [[buffer(1)]],
                       uint vertexId [[vertex_id]],
                       uint instanceId [[instance_id]] )
{
    v2f o;
    float4 pos = float4( vertexData[ vertexId ].position, 1.0 );
    o.position = instanceData[ instanceId ].instanceTransform * pos;
    o.color = half3( instanceData[ instanceId ].instanceColor.rgb );
    return o;
}
```

The `[[instance_id]]` attribute in MSL contains the value of the instance as provided by the runtime.

## Sample 5: Render 3D with Perspective Projection

`05-perspective` adds depth to rendered objects.

3D graphics are made by using a [perspective transformation](https://en.wikipedia.org/wiki/3D_projection#Perspective_projection).

The perspective transformation is defined in the math namespace.

```c++
simd::float4x4 makePerspective( float fovRadians, float aspect, float znear, float zfar )
{
    using simd::float4;
    float ys = 1.f / tanf(fovRadians * 0.5f);
    float xs = ys / aspect;
    float zs = zfar / ( znear - zfar );
    return simd_matrix_from_rows((float4){   xs,    0.0f,    0.0f,         0.0f },
                                 (float4){ 0.0f,      ys,    0.0f,         0.0f },
                                 (float4){ 0.0f,    0.0f,      zs,   znear * zs },
                                 (float4){    0,       0,      -1,            0 });
}
```

- `fovRadians` is the field of view angle in radians.
- `ys` represents the scaling factor for the y-coordinate.
- `xs` adjusts ys based on the aspect ratio (aspect), ensuring the correct scaling for the x-coordinate.
- `zs` represents the scaling factor for the z-coordinate.
- `znear` and `zfar` are the distances to the near and far clipping planes, respectively.

Two observations to make 
    1. the only output coordinate that is affected by the inputs fourth coordinate is the third (all 0's in fourth column except in third row). 
    2. the world-space z value is stored in the outputs fourth coordinate

Here is the perspective transformation applied in the shader.

```c++
pos = instanceData[instanceId].instanceTransform * pos;
pos = cameraData.perspectiveTransform * cameraData.worldTransform * pos;
```

## Sample 6: Light Geometry

The `06-Lighting` sample builds on the previous one.

The sample declares the `VertexData` structure with an additional vertex attribute, called a *normal*.  The equations to produce lighting effects use this normal attribute to determine the amount of light to apply. Both the host C++ code and GPU MSL code declare this structure so their memory layout match in both languages.

```c++
struct VertexData
{
    simd::float3 position;
    simd::float3 normal;
};
```

The renderer's `buildBuffers()` method uses this `VertexData` structure to define the vertices a cube with the `verts` array.

``` c++
shader_types::VertexData verts[] = {
    //   Positions          Normals
    { { -s, -s, +s }, { 0.f,  0.f,  1.f } },
    ...
}
```

The sample extends the interface between the vertex and the fragment stages in MSL. There are some [steps](https://en.wikipedia.org/wiki/Graphics_pipeline) between taking the output of the vertex shader and passing it into the fragment shader. These include 

- Primitive assembly
- Viewport transformation
- Clipping
- Rasterization

The normal attribute (and all others) are interpolated across the surface of each triangle, providing each fragment with its own interpolated values. 

``` c++
struct v2f
{
    float4 position [[position]];
    float3 normal;
    half3 color;
};
```

The fragment shader uses the interpolated normal to calculate the lit color of the fragment using a simple Lambert illumination model.

```c++
half4 fragment fragmentMain( v2f in [[stage_in]] )
{
    // assume light coming from (front-top-right)
    float3 l = normalize(float3( 1.0, 1.0, 0.8 ));
    float3 n = normalize( in.normal );

    float ndotl = saturate( dot( n, l ) );
    return half4( in.color * 0.1 + in.color * ndotl, 1.0 );
}
```

## Sample 7: Texture Surfaces

`07-texturing` adds a texture (image) onto the face of the rendered cubes.

In order to draw a texture, the code needs 3 things: 

1. An image accessible to the GPU.
2. Data showing Metal how to place the image upon each triangle 
3. Operations to apply the image to the rendered pixels

To create the image and make it available to the GPU, the sample introduces the `buildTextures` function.

To create a texture in Metal, use the `MTLTextureDescriptor` class. The descriptor provides information about the texture to create such as `width` and `height` of the image, its `pixelFormat`, `textureType`, `storageMode`, and `usage`. The renderer creates a texture from the `MTLDevice` object using this descriptor.

```objective-c
MTLTextureDescriptor* pTextureDesc = [[MTLTextureDescriptor alloc] init];
[pTextureDesc setWidth:tw];
[pTextureDesc setHeight:th];
[pTextureDesc setPixelFormat:MTLPixelFormatBGRA8Unorm];
[pTextureDesc setTextureType:MTLTextureType2D];
[pTextureDesc setStorageMode:MTLStorageModeManaged];
[pTextureDesc setUsage:MTLResourceUsageSample|MTLResourceUsageRead];

_pTexture = [_pDevice newTextureWithDescriptor:pTextureDesc];
```

This creates the object and allocates memory for the image. The renderer must still fill the memory with image data.

Typically, an application will fill the texture’s memory with data from an image file. Metal doesn't provide an API to load image data from files so apps must use custom code or an API which handles images such MetalKit or Image I/O. Instead of relying on such an API, this sample implements a simple algorithm to generate a checkerboard pattern. It allocates a temporary system memory buffer using `alloca` and then generates the image.

```c
uint8_t* pTextureData = (uint8_t *)alloca( tw * th * 4 );
```

Once the renderer has filled the temporary allocation, it copies the data to the texture object using the `replaceRegion` method.

```c++
_pTexture->replaceRegion( MTL::Region( 0, 0, 0, tw, th, 1 ), 0, pTextureData, tw * 4 );
```

```objective-c
[_pTexture replaceRegion:MTLRegionMake3D(0, 0, 0, tw, th, 1) mipmapLevel:0 withBytes:pTextureData bytesPerRow:tw*4];
```

Just like pipeline objects, textures are expensive to create. Create them once and reuse them as much as possible.

Once the renderer creates the texture, it must establish how Metal should place the image onto the cube faces. To accomplish this, the sample adds a *texture coordinate* attribute to each vertex.

The sample extends the `VertexData` structure to include a texture coordinate alongside vertex positions and normals.

```c++
struct VertexData
{
    simd::float3 position;
    simd::float3 normal;
    simd::float2 texcoord;
};
```

The `buildBuffers` method specifies a texture coordinate for each vertex in the array.

```c++
shader_types::VertexData verts[] = {
    //   Positions           Normals         Coordinates
    { { -s, -s, +s }, {  0.f,  0.f,  1.f }, { 0.f, 1.f } },
    ...
};
```

In the `draw` function, the renderer sets the texture using the encoder, making the image available to the fragment shader.

```objective-c
[pEnc setFragmentTexture:_pTexture atIndex:0];
```

The sample also makes a few changes to the shaders.

First, the shader's `v2f` structure includes a texture coordinate to interpolate when passed from the vertex shader to the fragment shader.

```c++
struct v2f
{
    float4 position [[position]];
    float3 normal;
    half3 color;
    float2 texcoord;
};
```

Second, the fragment shader adds a parameter for the texture object.

```c++
half4 fragment fragmentMain( v2f in [[stage_in]], texture2d< half, access::sample > tex [[texture(0)]] )
```

Finally, the fragment shader uses the interpolated texture coordinate to *sample* from the texture.

```c++
constexpr sampler s( address::repeat, filter::linear );
half3 texel = tex.sample( s, in.texcoord ).rgb;
```

This retrieves the texture data and passes it into the `texel` variable. The fragment shader mixes the `texel` color value with the result of the lighting calculations and outputs a final color.

```c++
half3 illumination = in.color.rgb * texel * saturate(dot(lightDirection, normal));
return half4(illumination, in.color.a); 
```

## Sample 8: Use the GPU for General Purpose Computation

The `08-compute` sample builds on the previous samples by leveraging the high bandwidth processing power offered by GPUs for general purpose computation. It uses a *compute* pipeline to generate the texture image on the GPU itself rather than creating it on the CPU.

To generate the texture on the GPU, the sample adds a `kernel` function written in MSL. This compute kernel accepts a texture with `access::write` as a parameter and calculates a color value to write to the texture. The `index` parameter is a 2D vector that the identifies the thread executed by the GPU. This kernel kernel uses `index` to determine x and y coordinate of the texel to write data to. The `gridSize` specifies the total size of the workload.

``` other
kernel void mandelbrot_set(texture2d< half, access::write > tex [[texture(0)]],
                           uint2 index [[thread_position_in_grid]],
                           uint2 gridSize [[threads_per_grid]])
```

Unlike fragment shaders, compute kernels do not output their results to render attachments. Instead, they can directly output texel data with the texture's `write()` method.

``` other
tex.write(half4(color, color, color, 1.0), index, 0);
```

The renderer uses the kernel to create a compute pipeline.

``` other
MTL::Function* pMandelbrotFn = pComputeLibrary->newFunction( NS::String::string("mandelbrot_set", NS::UTF8StringEncoding) );
_pComputePSO = _pDevice->newComputePipelineState( pMandelbrotFn, &pError );
```

Compute pipelines are more simple to build than render pipelines; they only contain a single function and do not need other state set before building them. Note that just like render pipelines, compute pipelines are expensive to create. The best practice is to create them once and reuse them.

In the previous sample, the `buildTextures()` method generates image data using the CPU and fills the texture's memory with the `replaceRegion()` method. In this sample, the renderer calls the `generateMandelbrotTexture()` method, which uses the GPU to fill the texture's memory. The  `generateMandelbrotTexture()` method creates a `MTL::ComputeCommandEncoder`. With this encoder, it sets the compute pipeline, specifies the texture to pass to the kernel, and, finally, executes the kernel with the `dispatchThreads()` method.

``` other
MTL::ComputeCommandEncoder* pComputeEncoder = pCommandBuffer->computeCommandEncoder();

pComputeEncoder->setComputePipelineState( _pComputePSO );
pComputeEncoder->setTexture( _pTexture, 0 );

MTL::Size gridSize = MTL::Size( kTextureWidth, kTextureHeight, 1 );

NS::UInteger threadGroupSize = _pComputePSO->maxTotalThreadsPerThreadgroup();
MTL::Size threadgroupSize( threadGroupSize, 1, 1 );

pComputeEncoder->dispatchThreads( gridSize, threadgroupSize );

pComputeEncoder->endEncoding();
```

To execute a kernel, the renderer explicitly specifies the size of the workload. It specifies this workload with a `MTL::Size` structure using the texture's width and height for the dimensions. The renderer passes this size as an argument to the `dispatchThreads()` function. The renderer also uses the the value returned by the compute pipeline's `maxTotalThreadsPerThreadgroup()` method to indicate a threadgroup size.

Once executed, the compute kernel fills the texture with a Mandelbrot set image. Metal applies this texture to the face of each cube just as it applied the checkerboard texture in the previous sample.

## Sample 9: Mix Compute with Rendering

The `09-compute-to-render` sample augments the previous one to regenerate the texture image each frame using a compute kernel right before issuing rendering commands. This enables implementing an animated texture effect, where a CPU-driven variable controls the zoom level of the Mandelbrot set.

To perform the texture generation in each frame, the sample simply encodes commands with the `generateMandelbrotTeture()` method to the same command buffer used for subsequent rendering commands.

``` other
// Update texture:

generateMandelbrotTexture( pCmd );

// Begin render pass:

MTL::RenderPassDescriptor* pRpd = pView->currentRenderPassDescriptor();
MTL::RenderCommandEncoder* pEnc = pCmd->renderCommandEncoder( pRpd );
```

By default, Metal tracks hazards for buffers and textures so performing compute work to write into a texture just before the GPU renders witht does not require any explicit synchronization.  Metal will detect the write operation on the texture and ensures that and draw calls that sample from that texture wait until the compute work is complete.

This ensures the results are correct, without the need to implement any GPU timeline synchronization logic or resource transitions.

## Sample 10: Capture GPU Commands for Debugging

The `10-frame-debugging` sample builds on the previous one by adding functionality to ease debugging of the Metal code. Specifically, the sample generates a *GPU frame capture*, which is a recording of Metal state and commands that you can examine in Xcode.

This sample triggers a capture under two different conditions: via a menu item, or after a short timeout. In both cases, the sample uses a `MTL::CaptureManager` object to begin the capture from within the renderer's `triggerCapture()` method. The method begins by obtaining the global capture manager and checking if the device supports capturing Metal commands:

``` other
MTL::CaptureManager* pCaptureManager = MTL::CaptureManager::sharedCaptureManager();
success = pCaptureManager->supportsDestination( MTL::CaptureDestinationGPUTraceDocument );
```

A device will only support capturing Metal commands if the application's Info.plist file has the `MetalCaputureEnabled` key set to `true`.

```
<dict>
    <key>MetalCaptureEnabled</key>
    <true/>
</dict>
```

For applications built as part of a bundle, Xcode embeds plists at build time. However apps, such as this sample, which are not part of a bundle, must explicitly link the plist file using the clang linker. The Makefile included with these samples uses the following linker flag to link the plist to this sample's executable.

```
sectcreate __TEXT __info_plist ./10-frame-debugging/Info.plist
```

Next, the renderer creates a `MTL::CaptureDescriptor` object. Here, it specifies that Metal should write the capture data to a file and designates where the file should appear.  It also specifies that Metal should capture all commands executed by the device.   

``` other
MTL::CaptureDescriptor* pCaptureDescriptor = MTL::CaptureDescriptor::alloc()->init();

pCaptureDescriptor->setDestination( MTL::CaptureDestinationGPUTraceDocument );
pCaptureDescriptor->setOutputURL( pURL );
pCaptureDescriptor->setCaptureObject( _pDevice );
```

* Note: it is important that the app has permissions to write a file to the destination, otherwise an error may occur.

The renderer calls the `startCapture()` method to immediately begin capturing commands.

``` other
success = pCaptureManager->startCapture( pCaptureDescriptor, &pError );
```

Until the renderer calls the `stopCapture()` method, Metal records all commands executed by the device.

``` other
MTL::CaptureManager* pCaptureManager = MTL::CaptureManager::sharedCaptureManager();
pCaptureManager->stopCapture();
```

When the capture completes, the sample automatically opens the .gputrace file in Xcode. However, the trace file persists even after the application exits, allowing you to open it anytime later.



