% clear
% sdrdev('Pluto');
% configurePlutoRadio('AD9364')
% Request user input from the command-line for application parameters
% userInput = helperFMUserInput;

% Calculate FM system parameters based on the user input
%[fmRxParams,sigSrc] = helperFMConfig(userInput);

fmRxParams.FrontEndFrameTime=0.0168;
fmRxParams.FrontEndSampleRate=228000;

sigSrc=comm.SDRRxPluto(...
       'CenterFrequency',92.4e6, ...%The channel you want to listen to (Hz)
            'GainSource','Manual', ...
                  'Gain',50,...%can control volume
        'ChannelMapping',1, ...
    'BasebandSampleRate',fmRxParams.FrontEndSampleRate,...
        'OutputDataType','single', ...
       'SamplesPerFrame',4410);

% Create FM broadcast receiver object and configure based on user input
fmBroadcastDemod = comm.FMBroadcastDemodulator( ...
    'SampleRate', fmRxParams.FrontEndSampleRate, ...
    'FrequencyDeviation', 75e3, ...
    'FilterTimeConstant', 7.5e-5, ...
    'AudioSampleRate', 45600, ...
    'Stereo', true);

% Create audio player
player = audioDeviceWriter('SampleRate',45600);

% Initialize radio time
radioTime = 0;

% Main loop
%while radioTime < 10   %time of playing (in seconds)
while 1
  rcv = sigSrc();
  lost = 0;
  late = 1;

  % Demodulate FM broadcast signals and play the decoded audio
  audioSig = fmBroadcastDemod(rcv);
  player(audioSig);

  % Update radio time. If there were lost samples, add those too.
  radioTime = radioTime + fmRxParams.FrontEndFrameTime + ...
    double(lost)/fmRxParams.FrontEndSampleRate;
end

% Release the audio and the signal source
release(sigSrc)
release(fmBroadcastDemod)
release(player)
