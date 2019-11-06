clearvars -except times;close all;warning off;
set(0,'defaultfigurecolor','w');
addpath /home/rypan/Project/Matlab/PlutoSDR/Network-Protocol-Simulation/library
addpath /home/rypan/Project/Matlab/PlutoSDR/Network-Protocol-Simulation/library/matlab

ip = '192.168.2.1';
addpath /home/rypan/Project/Matlab/PlutoSDR/Network-Protocol-Simulation/code/BPSK/transmitter
addpath /home/rypan/Project/Matlab/PlutoSDR/Network-Protocol-Simulation/code/BPSK/receiver

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

arrLength = ceil(length(stringToSend)/59);
sendArray = cell(1,arrLength);
seqNum = 0;

isRecieved = 0;
recievedStr = '';
next_index = 1;

init_time = clock;
while(etime(clock, init_time)<300)
    fprintf('receiving %d ...\n',next_index);

    %��¼����ʱ��
    sendTime = clock;
    while (etime(clock, sendTime) < 10)
        output = recieveData(s);
        I = output{1};
        Q = output{2};
        Rx = I+1i*Q;
        [rStr, isRecieved] = bpsk_rx_func(Rx(end/2:end));
        if (~isRecieved)
            fprintf('recieve nothing at all\n');
           continue;
        else
            if (abs(rStr(1, 1)) == next_index)
                    next_index = next_index + 1;
                    fprintf('recieve : %s \n', rStr(1,2:length(rStr)));
                    break;
            else
                fprintf('recieve is : %s \n', rStr(1,1:length(rStr)));
                fprintf('recieve nothing %d %c\n', abs(rStr(1, 1)),rStr(1, 1));
                continue
            end
        end
    end
    % ��ʱδ���յ�Ӧ���յ��ֶ�
    txdata = bpsk_tx_func(['NAK',char(next_index)]);
    txdata = round(txdata .* 2^14);
    txdata = repmat(txdata, 8,1);
    input{1} = real(txdata);
    input{2} = imag(txdata);
    fprintf('send NAK %d\n',next_index);
    sendData(s, input);
end
% fprintf('Transmission and reception finished\n');
% fprintf('recievedData: %s\n', recievedStr);
% 
% % Read the RSSI attributes of both channels
% rssi1 = output{s.getOutChannel('RX1_RSSI')};
% % rssi2 = output{s.getOutChannel('RX2_RSSI')};

s.releaseImpl();
