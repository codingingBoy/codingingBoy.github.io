---

layout: default
title: UIView Transform问题备忘

---
UIView Transform问题备忘
<!-- more -->


## UIView Transform

本篇主要内容是介绍使用UIView Transform 中遇到的问题，以及问题解决方法、后续遗留待分析问题

### 问题

当以及给UIVIew的tranform赋值后，再次赋值时UIView会跳动到另一个位置，然后从另一个位置开始动画。上述问题中包含3个小问题：

1. 跳动的位置与设置的transform的关系
2. 产生上述跳动的原因
3. 解决上述跳动的方法

### 解决方法

针对1、2两个问题暂时没有结论，针对3问题，解决方法如下：

设置帧动画：首先恢复原来的tranform，然后进行后续新的tranform赋值

参考链接：[UIView animation jumps at beginning](https://stackoverflow.com/questions/12535647/uiview-animation-jumps-at-beginning)