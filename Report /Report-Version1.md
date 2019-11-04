# 通原实验报告

## 概述

我们组基于 PlutoSDR，设计并完成了两个实验目标.
一: FM实现音频文件的传输.
我们利用FM模块和Matlab中的 `Communications Toolbox Support Package for Analog Devices ADALM-Pluto Radio`插件所提供的已经封装好的函数, 成功传输了一段音频文件. 在传输过程中,我们能完整做到自发自收和单收单发这两种模式.
二: 基于BPSK的文字传输系统.
在 Analogodevice 公司所提供的 libiio 硬件库源代码以及从网上找到的 BPSK.demo（Matlab实现）的基础上，我们设计并实现了可靠的无线通信传输系统。最终的效果是: 我们既能在一台 Pluto 设备上实现自发自收，也在此基础上，实现了两台 Pluto 设备的相互传输。在实际的无线信道中，可以传输任意长度的文字。同时, 我们为了传输的可靠性，使用了简化的停止等待协议。

### 操作系统： Manjaro(arch linux) 

## 实验原理

### PlutoSDR 的简单介绍

### FM音频传输的设计思路

### BPSK调制的原理

### BPSK文字传输系统的设计
1. 收发函数部分. `./library/matlab/iiio_sys_obj_matlab.m` 中,函数 `function ret = stepImpl(obj, varargin)` 实现了发射和接受数据.具体格式如下:
    ```matlab
    % Implement the data transmit flow
    writeData(obj.libiio_data_in_dev, varargin{1});

    % Implement the data capture flow
    [~, data] = readData(obj.libiio_data_out_dev);
    ```
    其中, `obj` 是代表了一个对象,而这个对象就是我们使用的 Pluto 开发板,这个开发板有很多的属性 (Properties), 我们就可以使用`obj.libiio_data_in_dev` 这样的形式来设置我们的开发板. 使用这样面向对象的代码能极大方便我们的开发流程.
2. 收发数据设置. 在 `./code/matlab/BPSK/transmitter/bpsk_tx_func.m` 中,原作者设置了要发送的128*4 = 512 bit 的数据。其中前 480 比特是有用信息（60 个字符），后 32 位用作循环冗余校验（CRC）。由于在其他地方设置了收发的数据长度而不好更改，这里我们就用了这 512 比特作为一个数据帧。为了支持任意长度的数据，需要把给定的不足 60 个字符的消
息结尾补没有意义的空白字符填充到 60.

    ```matalb
    function txdata = bpsk_tx_func(msgStr)
        %......
        for k = length(msgStr)+1 :60
        msgStr = [msgStr, char(0)];
        end
        %......
    end
    ```
    当发送长消息时，以 60 个字符一切割，在接受到之后只需要抹去最后的空白字符就可以恢复原始消息。

3. 停止等待协议.这个是我们实现 `./code/BPSK/stop_wait.m`的主要思路.我们设计的停止等待协议是这样的:
    * 帧序号有 0 和 1 两种，在两种之间跳变
    * 每帧的前 3 个字符用作帧序号和其他控制信息。即有效信息从 60 个字符减少到 57 个字符
    * 发送方每次发送一个帧，并开始计时
    * 接收方如果收到一个帧，且该帧的序号是自己期望的，则把收到的帧序号返回，并保存相应数据
    * 发送方如果没有到规定的超时时间（这里是 10 秒）：
        * 持续监听返回值
        * 如果收到自己刚刚发送到的帧序号
        * 发送下一帧
    * 否则
        * 继续监听,直到超时
    * 发送方如果超时,重新传输刚才的帧
    * 停止等待协议原理图:

4. 滑动窗口协议. 我们设计的滑动窗口协议规则如下
    * 发送方和接收方窗口大小均设置为 5
    * 为了避免序号回滚时引起歧义，序号的个数设置为窗口大小的 2 倍，即取 1- 10
    * 发送方维护发送窗口，在等待发送的数据数组上滚动
    * 接收方维护接收窗口，判断收到的数据帧号是否落在自己的窗口内，并酌情保存数据
    * 接收方发现有一段序号连续的数据后（顺序正常），滑动自己的窗口，并返回这些连续的数据中的最大序号
    * 发送方一次发完从上次发送的位置到窗口末尾中的所有数据，并开始计时
    * 发送方如果没有到规定的超时时间（这里是 10 秒）
        * 持续监听返回值
        * 如果收到的帧序号落在自己的发送窗口中，且与之前收到的帧序号不一样
            * 滑动窗口并开始发送下一串数据
        * 否则
            * 继续监听，直到超时
    * 发送方如果超时，重新传输窗口中的所有数据
    * 滑动窗口协议原理图:


## 实验过程

    我们的实验过程主要是分为三部分, 环境安装和配置; 基于FM的音频传播; 基于BPSK的文字传输.

### 环境搭建和配置

1. 在Matlab上安装 `Communications Toolbox Support Package for Analog Devices ADALM-Pluto Radio `

2. 安装的 libiio 库文件： windows 和 linux 下配置的方法稍有不同
    * windows. 到 analog官网<sup>[1]</sup> 上下载相应的 `.exe` 文件安装即可
    * linux. 需要从 analog 中下载源码,自己在本地编译(编译过程不在此展开,请自己查阅官方 wiki 文档实现). **请注意**: 编译时需要使用超级管理员权限,同时,在编译的最后需要和 Matlab 做结合.因此,本地的 Matlab 需要以超级管理员身份运行和激活,否则会报错.

3. 配置 MingW -- C语言编译器
    * windows. 下载 MingW --> 设置环境变量 --> 在 Matlab 相应配置
    * linux. linux 下自带 gcc+gdb  编译环境,所以不需要配置

### 基于FM的音频传播

* 

```matlab
%% 发射初始化
txPluto = sdrtx('Pluto','RadioID','usb:0',...
    'CenterFrequency',92.4e6,...
    'Gain',-0,...
    'ChannelMapping',1,...
    'BasebandSampleRate',228000);
txPluto.ShowAdvancedProperties = true;

afr=dsp.AudioFileReader('Scarborough Fair.flac','SamplesPerFrame',44100/2);
adw = audioDeviceWriter('SampleRate', afr.SampleRate);
mod=comm.FMBroadcastModulator('AudioSampleRate',afr.SampleRate, ...
    'SampleRate',txPluto.BasebandSampleRate,'Stereo',false);
%data=audioread('Scarborough Fair.flac');
%% 接收初始化
sigSrc=comm.SDRRxPluto(...
    'CenterFrequency',92.4e6,...%The channel you want to listen to (Hz)
    'GainSource','Manual',...
    'Gain',50,...%can control volume
    'ChannelMapping',1,...
    'BasebandSampleRate',228000,...%228000
    'OutputDataType','single',...
    'SamplesPerFrame',45600*5/2);%5.2:发射有少量间断;5似乎行;4.2:接收有间断;4.8:接收过一段时间间断一次

% Create FM broadcast receiver object and configure based on user input
fmBroadcastDemod = comm.FMBroadcastDemodulator(...
    'SampleRate', 228000, ...
    'FrequencyDeviation', 75e3, ...
    'FilterTimeConstant', 7.5e-5, ...
    'AudioSampleRate', 45600, ...
    'Stereo', true);

% Create audio player
player = audioDeviceWriter('SampleRate',45600);

while ~isDone(afr)
    data = afr();
    %adw(data);
    data=(data(:,1)+data(:,2))/2;
    data=mod(data);
    underflow=txPluto(data);

    rcv = sigSrc();
    audioSig = fmBroadcastDemod(rcv);
    player(audioSig);
end

```

### 代码结构&文件作用分析
![CodeStructure1](https://raw.githubusercontent.com/rongyupan/PlutoSDR-BPSK/master/Pictures/CodeStructure1.png)

* `/library/matlab`
    * 这下面保存着主要的 libio库的matlab函数实现. 这个库的作用就是作为 Matlab 和 PlutoSDR进行交互的文件.
    * 我们主要使用的是其中的 `iiio_sys_matlab.m` 文件中的函数, 比如说发送和接受数据, 设置pluto 的频段等参数等等作用. 
    * `ad9361.cfg` 则是对于 PlutoSDR 的芯片参数进行配置的文件.
    * `iio.h` 是用C语言编写的硬件函数库,而这也是我们需要在基本环境配置中添加C语言编译器的原因,在运行过程中,需要编辑头文件来达到操作硬件的目的.
* `/code/`
    * `go_back_n_recv.m` & `go_back_n_send.m` 是我们作为单独收和单独发的主要函数文件.
    * `slide_windows_receiver.m` 则是实现了窗口滚动接受的效果,相当于在原先接受的基础上进行了提升.
    * `stop_wait.m` 则是利用了停止等待协议,实现了对一段文本的自发自收.

    ![CodeStructure2](https://raw.githubusercontent.com/rongyupan/PlutoSDR-BPSK/master/Pictures/CodeStructure2.png)

* `/code/BPSK/`
    * `../receiver` & `../transmitter` 这是我们找到的参考例程. 主要的作用是实现了 BPSK 的调制和解调. 我们只需要将这些文件的位置添加到路径当中即可调用.


### 自发自收的实现

#### 主要代码解读
```matlab
clearvars -except times;close all;warning off;
set(0,'defaultfigurecolor','w');
% 添加 libiio 库文件
addpath ..\library
addpath ..\library\matlab

% 设置 pluto 需要使用的ip地址
% 添加 BPSK 调制解调代码路径
ip = '192.168.2.1';
addpath BPSK\transmitter
addpath BPSK\receiver

%% System Object Configuration
s = iio_sys_obj_matlab; % MATLAB libiio Constructor
s.ip_address = ip;
s.dev_name = 'ad9361';
s.in_ch_no = 2;
s.out_ch_no = 2;
s.in_ch_size = 42568;
s.out_ch_size = 42568*8;

s = s.setupImpl();

input = cell(1, s.in_ch_no + length(s.iio_dev_cfg.cfg_ch));
output = cell(1, s.out_ch_no + length(s.iio_dev_cfg.mon_ch));

% Set the attributes of AD9361
input{s.getInChannel('RX_LO_FREQ')} = 2e9;
input{s.getInChannel('RX_SAMPLING_FREQ')} = 40e6;
input{s.getInChannel('RX_RF_BANDWIDTH')} = 20e6;
input{s.getInChannel('RX1_GAIN_MODE')} = 'manual';%% slow_attack manual
input{s.getInChannel('RX1_GAIN')} = 10;
% input{s.getInChannel('RX2_GAIN_MODE')} = 'slow_attack';
% input{s.getInChannel('RX2_GAIN')} = 0;
input{s.getInChannel('TX_LO_FREQ')} = 2e9;
input{s.getInChannel('TX_SAMPLING_FREQ')} = 40e6;
input{s.getInChannel('TX_RF_BANDWIDTH')} = 20e6;

%% Transmit and Receive using MATLAB libiio

stringToSend = 'Once a heroic Jedi Knight, Darth Vader was seduced by the dark side of the Force, became a Sith Lord, and led the Empire"s eradication of the Jedi Order. He remained in service of the Emperor -- the evil Darth Sidious -- for decades, enforcing his Master��s will and seeking to crush the fledgling Rebel Alliance. But there was still good in him ...';

arrLength = ceil(length(stringToSend)/57);
sendArray = cell(1,arrLength);
seqNum = 0;
for index = 1:arrLength
    seqNumStr = ['00', int2str(seqNum)];
    if seqNum == 0 
        seqNum = 1;
    else 
        seqNum = 0;
    end
    if index*57 > length(stringToSend)
        sendArray(index) = {[seqNumStr,stringToSend(index*57-56:length(stringToSend))]};
    else
        sendArray(index) = {[seqNumStr,stringToSend(index*57-56:index*57)]};
    end
end

index = 1;
isRecieved = 0;
RcurrentSeq = '0';
recievedStr = '';
while(index <= arrLength)
    TcurrentSeq = sendArray{index}(3);
    fprintf('Transmitting Data Block %s ...\n',TcurrentSeq);

    txdata = bpsk_tx_func(sendArray{index}); 
    txdata = round(txdata .* 2^14);
    txdata=repmat(txdata, 8,1);
    input{1} = real(txdata);
    input{2} = imag(txdata);
    sendData(s, input);

    sendTime = clock;
    while (etime(clock, sendTime) < 10)
        output = recieveData(s);
        I = output{1};
        Q = output{2};
        Rx = I+1i*Q;
        [rStr, isRecieved] = bpsk_rx_func(Rx(end/2:end));
        if (~isRecieved)
           continue;
        else
            if (rStr(1, 1:3) == 'ACK')
                if (rStr(1, 4) == TcurrentSeq)
                    fprintf('Data Block %s ACKed...\n',TcurrentSeq);
                    index = index + 1;
                    break;
                end
            else
                if (rStr(1, 3) == RcurrentSeq)
                    fprintf('Data Block %s Received...\n',RcurrentSeq);
                    if (length(rStr) == 16)
                        temp = [rStr(1, 4:16), rStr(2,:), rStr(3,:), rStr(4,:)];
                        recievedData = temp(1:find(ismember(temp, char(0)), 1 ) - 1);
                    else
                        recievedData = rStr(1, 4:length(rStr));
                    end
                    fprintf('recievedData: %s\n', recievedData);
                    recievedStr = [recievedStr, recievedData];
                    if (RcurrentSeq == '0')
                        RcurrentSeq = '1';
                    else
                        RcurrentSeq = '0';
                    end
                end
                txdata = bpsk_tx_func(['ACK', rStr(1, 3)]);
                txdata = round(txdata .* 2^14);
                txdata=repmat(txdata, 8,1);
                input{1} = real(txdata);
                input{2} = imag(txdata);
                fprintf('Transmitting ACK...\n');
                sendData(s, input);
                output = {};
            end
        end
    end
end
fprintf('Transmission and reception finished\n');
fprintf('recievedData: %s\n', recievedStr);

% Read the RSSI attributes of both channels
rssi1 = output{s.getOutChannel('RX1_RSSI')};
% rssi2 = output{s.getOutChannel('RX2_RSSI')};

s.releaseImpl();

```

#### 测试结果

#### 结果分析

## 问题总结

### 环境搭建和配置
1. 在Matlab上安装 `Communications Toolbox Support Package for Analog Devices ADALM-Pluto Radio ` 失败
    * 解决方案一： 需要在 Matlab 中设置 `web_proxy`，使用外网下载相应的配置文件；
    * 解决方案二： 在 Analogodevice 的 github<sup>[1]</sup> 仓库中下载已经打包好的 toolbox 文件

## 心得体会

## 注释和参考文档
[1] analog官网: https://wiki.analog.com/  
[1] github仓库网站： https://wiki.analog.com/resources/tools-software/