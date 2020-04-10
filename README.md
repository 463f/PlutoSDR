# PlutoSDR-BPSK

PlutoSDR + MATLAB2019b(Linux Version)

## Intro:
This project is based on PlutoSDR and MATLAB to design a communication sysytem.

## FM: transmit music files.

Install the Communication Toolbox for PlutoSDR in MATLAB Addons.

### `Rx.m & Tx.m`

Using 2 pluto devices: one computer runs `Tx.m` to send music in FM, and the other one runs `Rx.m`, which will receieve and play the music.

### `RT.m` 

Run this matlab file in one PC. The effect is the same as the below.

**This code is forked from another repo of github.** If you are looking for the orign, just search in the github.

## BPSK: transmit text message

If you search github, you can find several versions of repos on how to accomplish BPSK based on `libiio library`. 
I tried all of them and encountered many errors. 
How to fix errors and environment configuration of MATLAB can be found in the Report.(Written in Chinese)

**The code is forked from the other related repos of github.**

## Write in the end

Actually, Mathworks.corp also provides many reference materials. 
For example, MATLAB has **a script on the transmission of image using plutoSDR.** 

You can use command  
`edit plutoradioWLANTransmitReceiveExample` 
to run this MATLAB file. 
