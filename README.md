# PlutoSDR-BPSK
## Using PlutoSDR to transfer text message.

## Env: PlutoSDR + MATLAB2019b(Linux Version)

## Intro:
This is a project launched by school which requires us to design a commnication system using PlutoSDR and MATLAB.
This repo contains 2 parts, FM & BPSK.

## Part I: FM

* You have to install the Communication Toolbox for PlutoSDR in MATLAB Addons.
* Rx.m & Tx.m. Using 2 pluto devices, one computer runs Rx.m and the other one runs Tx.m; then you can hear the music from computer running Rx.m
* RT.m. Run this code in just one PC. The effect is the same as the below. 
* This code is forked from another repo of github. If you are looking for the orign, just search in the github.

## Part II: BPSK

* There're several version of repos to finish the BPSK using `libiio library` if you search github. I tried all of them and encountered many errors. The solutions and how to configure the environment of MATLAB is in the Report(Written in Chinese)
* The code is forked from the other related repos of github.

## Write in the end

Actually, Mathworks also provides many reference materials. For example, MATLAB has a script on the transmission of image using plutoSDR. You can use command  `edit plutoradioWLANTransmitReceiveExample` to read this MATLAB file. 
