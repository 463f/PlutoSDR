# 通原实验报告 -- 基于BPSK的文字传输系统

## 概述

我们组基于 PlutoSDR 设备，在 Analogodevice 公司所提供的 libiio 硬件库源代码以及从网上找到的 BPSK.demo（Matlab实现）的基础上，实现了可靠的无线通信传输系统。我们既能在一台 Pluto 设备上实现自发自收，也在此基础上，实现了两台 Pluto 设备的相互传输。在实际的无线信道中，可以传输任意长度的文字。我们为了传输的可靠性，使用了简化的停止等待协议。
### 操作系统： Manjaro(arch linux) 

## 实验原理

1. BPSK调制的原理
2. PlutoSDR 的简单介绍
3. Pluto + Matlab 使用方法

## 实验过程

### 环境搭建和配置

1. 在Matlab上安装 `Communications Toolbox Support Package for Analog Devices ADALM-Pluto Radio `

2. 安装的 libiio 库文件： windows 和 linux 下配置的方法稍有不同
    * windows. 到 analog官网<sup>[1]</sup> 上下载相应的 `.exe` 文件安装即可
    * linux. 需要从 analog 中下载源码,自己在本地编译. 请注意: 编译时需要使用超级管理员权限,同时,在编译的最后需要和 Matlab 做结合.因此,本地的 Matlab 需要以超级管理员身份运行和激活,否则会报错.

3. 配置 MingW -- C语言编译器
    * windows. 下载 MingW --> 设置环境变量 --> 在 Matlab 相应配置
    * linux. linux 下自带 gcc+gdb  编译环境,所以不需要配置

### 代码结构


## 问题总结

### 环境搭建和配置
1. 在Matlab上安装 `Communications Toolbox Support Package for Analog Devices ADALM-Pluto Radio ` 失败
    * 解决方案一： 需要在 Matlab 中设置 `web_proxy`，使用外网下载相应的配置文件；
    * 解决方案二： 在 Analogodevice 的 github<sup>[1]</sup> 仓库中下载已经打包好的 toolbox 文件

## 心得体会

## 注释和参考文档
[1] analog官网: https://wiki.analog.com/  
[1] github仓库网站： https://wiki.analog.com/resources/tools-software/