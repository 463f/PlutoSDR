clearvars -except times;close all;warning off;
set(0,'defaultfigurecolor','w');
addpath ..\library
addpath ..\library\matlab

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

stringToSend = 'Once a heroic Jedi Knight, Darth Vader was seduced by the dark side of the Force, became a Sith Lord, and led the Empire"s eradication of the Jedi Order. He remained in service of the Emperor -- the evil Darth Sidious -- for decades, enforcing his Master''s will and seeking to crush the fledgling Rebel Alliance. But there was still good in him ...';

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
