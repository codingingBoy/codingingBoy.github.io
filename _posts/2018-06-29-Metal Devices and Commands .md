---

layout: default
title: Metal Devices and Command

---
Swift Metal Devices and Command
<!-- more -->


## Swift Metal Devices and Command

本篇是对Metal官方文档的理解和复述，文档主要内容包括：获取Metal设备、创建Metal View、创建和执行GPU指令、渲染

MetalKit 中最常用的特性 MTKView 是 "Metal-specific Core Animation functionality" + NSView/UIView 的结合，MTKView 建立渲染的render loop， 并持续地给每一帧提供 2D 的展示数据源。

### Rendering Loop

rendering loop 是一个被 MTKView 按帧率调用的 MTKViewDelegate，这个delegate 一般被定义为独立的类，以方便管理渲染。

rendering loop（delegate）主要的功能是响应 MTKView 的事件（"Respond to View Events"），事件包括：

1、渲染size变化：`mtkView:drawableSizeWillChange:`，当 window 大小变化、layout重置、方向改变等事件会触发

2、渲染帧：`drawInMTKView:`，当需要渲染帧时被调用


### Metal Device

Metal Device 是一个代表GPU 的对象，通过`MTLCreateSystemDefaultDevice()` 获取到默认的设备GPU：MTLDevice，可以通过 MTLDevice 对象创建与GPU交互的条件。

MTLDevice 通过 MTLCommandQueue 来执行 GPU 指令，而针对每一帧的GPU指令通过 MTLCommandBuffer 来提供

```
id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
```

### Metal Command

上述 MTLCommandBuffer 用于执行每一帧的command，但是这些指令需要针对GPU去encode，这个encoder通过 MTLRenderPassDescriptor 来创建，而 MTLRenderPassDescriptor是通过当前 MTLCommandBuffer 来获取。这里没有详细展开描述。

### Finalize a Frame

当 MTLRenderCommandEncoder 调用 endEncoding 时，encode结束，接下来只接收两个指令：present 和 commit.

present 指令也就是待encode的指令执行完成之后执行绘制：

```
[commandBuffer presentDrawable:view.currentDrawable];
```

commit 指令是将encode的指令提交给 MTLCommandBuffer，添加到commandQueue，被Device执行：

```
[commandBuffer commit];
```