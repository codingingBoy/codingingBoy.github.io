---

layout: default
title: Metal TextureCoordinate

---
本篇主要介绍 MTLTextureCoordinate 的功能，并结合实例中可能出现的问题。
<!-- more -->


## Metal TextureCoordinate

Metal 绘制纹理MTLTexture 时需要用到 MTLTextureCoordinate，本篇主要介绍 MTLTextureCoordinate 的功能，并结合实例中可能出现的问题。


### Texture Coordinates 官方文档

本节是对Metal官方文档中关于 Texture Coordinates 的翻译，原文参考 [Basic Texturing](https://developer.apple.com/documentation/metal/basic_texturing) 。

片元函数的作用是处理输入的片元数据，输出到绘制区域某个像素的颜色。Sample（官方文档sample）中展示了将纹理 Texture 应用到每个像素点（通过纹理的数据给出每个像素点的颜色），并展示到屏幕上。因此 sample 中的片元函数需要读取每个像素点的颜色并输出到绘制区域。

对于2D的纹理，texture coordinates 是一个float2（一行两列的数组），x、y方向的值都是 0.0~1.0。(0.0, 0.0)对应图片 data的首字节（图片左下角）。(1.0, 1.0)对应图片 data的末字节（图片右上角）。依次可以通过(0.5, 0.5)取纹理中心点。

Visualizing Texture Coordinates

### Map the Vertex Texture Coordinates

上节中翻译了Metal 文档中关于Texture Coordinates的说明，在输入顶点信息中附带了 Texture Coordinates：

```
static const AAPLVertex quadVertices[] =
{
    // Pixel positions, Texture coordinates
    { {  250,  -250 },  { 1.f, 0.f } },
    { { -250,  -250 },  { 0.f, 0.f } },
    { { -250,   250 },  { 0.f, 1.f } },

    { {  250,  -250 },  { 1.f, 0.f } },
    { { -250,   250 },  { 0.f, 1.f } },
    { {  250,   250 },  { 1.f, 1.f } },
};
```

也就是顶点坐标 Pixel positions 与 Texture coordinates的对应关系：左下角对应（0，0），右上角对应（1，1）。

### PNG图片Texture 绘制

官方Sample中以tga图片绘制纹理，按照sample中的方法绘制png图片生成的纹理时，会发现图片倒置了。

先放出结论：png图片data的首字节并不是对应图片的左下角，而是图片的左上角，所以Texture Coordinates 对应的值应该是：左上角（0，0），右下角（1，1）。

文档中在说明(0.0, 0.0)对应图片 data的首字节，同时说明左下角，这应该是对tga图片而言，对png、jpg这些常见图片格式而言，data的排列是从左上到右下，因此调整 Texture Coordinates 即可得到正确的纹理绘制结果。

### Texture Coordinates 作用

在开始学习Metal之前没有OpenGL等图形绘制的学习经历，不大理解Texture Coordinates到底是什么。从完整的Metal sample可以了解到Texture Coordinates 是用在片元函数中，从Texture里取对应点的rgba值，输入的坐标（0，0）为左上角，（width，height）为右下角，而（0，0）点从纹理中取值应该是首字节，依靠的是Texture Coordinates，因此Texture Coordinates 就是从Texture 的data中取像素点的颜色时的坐标，是data中的坐标。
