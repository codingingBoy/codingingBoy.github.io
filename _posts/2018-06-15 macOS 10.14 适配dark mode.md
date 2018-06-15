---

layout: default
title: 

---
macOS app 适配 10.14 Dark Mode<!-- more -->

## Dark MOde Overview

Dark Mode 是macOS 10.14 中出现的系统皮肤特性，不是一个随着使用场景的亮度自动调节的方案。详细科普参考 [Supporting Dark Mode in Your Interface](https://developer.apple.com/documentation/appkit/supporting_dark_mode_in_your_interface#overview)


## 适配 Dark Mdoe

在app 中，当切换 system preference -> general 中 Appearance、Accent color、Highlight color时，系统app会随之变化，满足AppKit自适应条件的控件也会随之变化。Appearance的继承级别是：system -> NSApplication -> NSWindow -> NSView -> subview 。通常App中 的颜色和切图都是定制，所以通常需要额外适配两套UI，适配包括图片、颜色的适配。

### 颜色适配

#### AppKit的自适应方案

AppKit中的NSView、NSWindow、NSPanel、NSMenue以及NSViewController的view等（只列举了常用的类，其它类有待确认），设置颜色属性为NSColor中定义的 sementic color（eg.  labelColor、 controlColor、 controlBackgroundColor），会随系统appearance变化。

自适应的前提是没有在代码中写死appearance，在Appearance的继承级别中：system -> NSApplication -> NSWindow -> NSView -> subview，如果设置了NSApp.appearance，那么在后续切换系统的appearance时，app将是固定的appearance，而不会随系统变化。

#### 适配自定义颜色

自定义颜色如果可以设置为labelColor、 controlColor、 controlBackgroundColor这些常量，可以直接自动适配，不需要额外的适配工作。当控件为自定义控件类，或者设置的颜色是我们自定义的一个32位sRGB色值，需要通过 Color set 的方式，在不同的模式下使用不同的颜色。

<p align="center"> 
	<img src="/assets/images/darkMode_change.png">
</p>

<p align="center"> 
切换系统 appearance
</p>  

<p align="center"> 
	<img src="/assets/images/darkMode_colorset.png">
</p>

<p align="center"> 
color set 设置不同模式颜色
</p>  

<!-- darkMode_colorset -->

color set 以及 NSColor.init(named: NSColor.Name.init("name")) 的方式只适用于 10.13以上系统，适配版本低于10.13时，需要在代码中手动再设置一次所需颜色，否则为该控件默认颜色。

### 适配图片

适配图片问题上，AppKit并没有自适配方案，如果需要根据不同appearance切换图片，可以将image set 的 appearance选项设置为“Any、light、dark”，填充不同模式的切图即可。

适配dark mode之后，切图数量会增加，会直接增加app大小。

### 其它及注意事项

1. 监听App切换appearance

```
DistributedNotificationCenter.default().addObserver(forName: NSNotification.Name.init("AppleInterfaceThemeChangedNotification"), object: nil, queue: OperationQueue.main) { (notification) in

}
```

写死 NSApp.appearance时不会触发上述通知。


2. 获取当前App的appearance

```
let mode = UserDefaults.standard.string(forKey: "AppleInterfaceStyle")
// mode = "dark" 或者 nil
```


