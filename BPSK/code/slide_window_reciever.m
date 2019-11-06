clearvars -except times;close all;warning off;
set(0,'defaultfigurecolor','w');
addpath ./library/
addpath ./library/matlab

ip = '192.168.2.1';
addpath ./code/BPSK/transmitter
addpath ./code/BPSK/receiver

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
input{s.getInChannel('RX_LO_FREQ')} = 3e9;
input{s.getInChannel('RX_SAMPLING_FREQ')} = 40e6;
input{s.getInChannel('RX_RF_BANDWIDTH')} = 80e6;
input{s.getInChannel('RX1_GAIN_MODE')} = 'manual';%% slow_attack manual
input{s.getInChannel('RX1_GAIN')} = 10;
% input{s.getInChannel('RX2_GAIN_MODE')} = 'slow_attack';
% input{s.getInChannel('RX2_GAIN')} = 0;
input{s.getInChannel('TX_LO_FREQ')} = 3e9;
input{s.getInChannel('TX_SAMPLING_FREQ')} = 40e6;
input{s.getInChannel('TX_RF_BANDWIDTH')} = 20e6;

%% Receive Message
global windowSize
global startSeq
global endSeq;
global recievedData;
global recievedBuffer;
global isRecievedBuffer;

windowSize = 5;
startSeq   = 0;
endSeq     = windowSize - 1;
ackSeq     = 0;
recievedData = '';
recievedBuffer = cell(1, windowSize);
isRecievedBuffer = zeros(1, windowSize);

while(1)
%     strToSend = [char(0), char(12), 'asdfgasdfgh\n'];
%     fprintf(strToSend);
%     txdata = bpsk_tx_func(strToSend);
%     txdata = round(txdata .* 2^14);
%     txdata=repmat(txdata, 8,1);
%     input{1} = real(txdata);
%     input{2} = imag(txdata);
%     sendData(s, input);
%     continue;

    output = recieveData(s);
    I = output{1};
    Q = output{2};
    Rx = I+1i*Q;
    [rStr, isRecieved] = bpsk_rx_func(Rx(end/2:end));

    % �ж�crcУ����
    if (isRecieved && ~isempty(rStr))
        recievedSeq = abs(rStr(1, 1));
        frameLength = abs(rStr(1, 2));
        fprintf('recieved frame seq: %d\nframeLength: %d\nrStr data: %s\n', abs(recievedSeq), abs(frameLength), rStr);
        % ������յ���֡�ų�������
        if (rStr(1, 1) < char(startSeq) || rStr(1, 1) > char(endSeq))
            % ����ACK + �ڴ��յ����ź�
            strToSend = [char(6), char(startSeq)];
            txdata = bpsk_tx_func(strToSend);
            txdata = round(txdata .* 2^14);
            txdata=repmat(txdata, 8,1);
            input{1} = real(txdata);
            input{2} = imag(txdata);
            sendData(s, input);
            fprintf('send ACK %d', startSeq);
            continue;
        end

        putIsRecieved(recievedSeq);     % ��Ƕ�Ӧλ���յ�
        putRecievedBuffer(recievedSeq, rStr); % �����յ���֡���뻺��buffer

        % ��������
        while(isRecievedBuffer(1))
            slideWindow();
        end
        strToSend = [char(6), char(startSeq)];
        txdata = bpsk_tx_func(strToSend);
        txdata = round(txdata .* 2^14);
        txdata=repmat(txdata, 8,1);
        input{1} = real(txdata);
        input{2} = imag(txdata);
        sendData(s, input);
        fprintf('send ACK %d', startSeq);
    end
end


function putIsRecieved(recievedSeq)
    global isRecievedBuffer;
    global startSeq;
    temp = recievedSeq - startSeq + 1;
    if (temp < 0)
        temp = temp + 256;
    end
    isRecievedBuffer(temp) = 1;
end

function putRecievedBuffer(recievedSeq, rStr)
    global startSeq;
    global recievedBuffer;

    temp = recievedSeq - startSeq + 1;
    if (temp < 0)
        temp = temp + 256;
    end
    % ��buffer + ȷ���Ƿ�����
    if(rStr(1, 2) <= 14)
        recievedBuffer{temp} = rStr(1, 3:2+abs(rStr(1, 2)));
    elseif(rStr(1, 2) <= 30)
        recievedBuffer{temp} = [rStr(1, 3:16), rStr(2, 1:(abs(rStr(1, 2))-14))];
    elseif(rStr(1, 2) <= 46)
        recievedBuffer{temp} = [rStr(1, 3:16), rStr(2, :), rStr(3, 1:(abs(rStr(1, 2))-30))];
    else
        recievedBuffer{temp} = [rStr(1, 3:16), rStr(2, :), rStr(3, :), rStr(4, 1:(abs(rStr(1, 2))-46))];
    end
end

function seq = seqAddByOne(seq)
    seq = seq + 1;
    if (seq > 255)
       seq = seq - 256; 
    end
end

function slideWindow()
    global windowSize
    global startSeq
    global endSeq;
    global recievedData;
    global recievedBuffer;
    global isRecievedBuffer;

    % ������
    recievedData = [recievedData, recievedBuffer{1}];

    % �ƶ�recievedBuffer
    temp = cell(1, windowSize);
    for i=1:windowSize - 1
       temp{i} =  recievedBuffer{i+1};
    end
    temp{windowSize} = [];
    recievedBuffer = temp;
    
    % �ƶ�isRecievedBuffer
    temp = [isRecievedBuffer(2:5), 0];
    isRecievedBuffer = temp;

    % �ƶ�����
    startSeq = seqAddByOne(startSeq);
    endSeq = seqAddByOne(endSeq);
end
