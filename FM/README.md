# PlutoSDR



你是要去斯卡布罗集市吗？那里青菜3块一斤，牛肉20块一斤。



Before running the programs, make sure you have *Communications Toolbox Support Package for Analog Devices ADALM-Pluto Radio* ready. Connect ADALM-PLUTO to your computer, and run
```
sdrdev('Pluto');
configurePlutoRadio('AD9364')
```



in MATLAB for only once, which assures that your Pluto can handle FM frequency.



**Rx.m** works as a radio receiver. You can listen to all the commercial FM radio programs. 



**Tx.m** builds your own broadcasting station by transmitting FM signals! The default content is *Scarborough Fair.flac*. You can enjoy the music via radio app in your smartphone! ***BE AWARE THAT broadcasting radio signals without permission can be illegal. DO NOT use an occupied frequency!***



I understand that you may want a program to broadcast your real-time speech. I probably will not be available to develop such a program. You may first build a recording program, and then FMmodulate every frame to broadcast them. 
