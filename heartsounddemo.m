  function gui(op)
    global F_ANALYSIS H_PLAY signal sample_rate AXIS_PLAY
    %disp(nargin) number of inputs given
    if nargin == 0 % if no input argument, draw the GUI
        op = 0;
    end
  
switch op
case 0 %draw figure
    close all    
    width = 950;
    height = 400;
    
    F_ANALYSIS = figure('Position',[100 100 width height],...
        'NumberTitle','off',...
        'Color',[.8 .8 .8],...
        'Name','Heart Sound Analysis');
    createtextbox(F_ANALYSIS);
    createtextbox2(F_ANALYSIS);
    H_PLAY(1) = uicontrol('Style','pushbutton',... %load button
        'Units','normalized',...
        'Position',[190/width (height-350)/height 80/width 30/height],...
        'FontWeight','bold',...
        'String','Load',...
        'CallBack','gui(1)');
    H_PLAY(2) = uicontrol('Style','pushbutton',... % play button
      'Units','normalized', ...
      'Position',[300/width (height-350)/height 80/width 30/height],...
      'ForegroundColor',[.2 .4 .2],...
      'FontWeight','bold',...
      'String','Play',...
      'Enable','off',...
      'CallBack','gui(2)');
     
       H_PLAY(3) = uicontrol('Style','pushbutton',... % Save data to wav file
    'Position',[(width-500)/width (height-75)/height 75/width 25/height],...   
    'Enable','off',...
      'CallBack','gui(3)');  
  
    H_PLAY(6) = uicontrol('Style','pushbutton',... % record button
      'Units','normalized',...
      'Position',[75/width (height-350)/height 80/width 30/height],...
      'ForegroundColor',[1 0 0],...
      'FontWeight','bold',...
      'String','Play',...
      'String','Record',...
      'Visible','on',...
      'CallBack','gui(6)');

case 1
    filename = inputdlg('Enter name of file sound','Input',1,{'hr3.wav'});
    %filename = 'hr.wav';
    %disp('playing hr.wav');
    [signal,sample_rate] = audioread(char(filename));
    signal = (signal(:,1)+signal(:,2))/2;
    if (max(signal) > abs(min(signal)))
        m = max(signal);
    else
        m = abs(min(signal));
    end
    signal = signal / m;
    sample_rate = sample_rate(1,1);
    set(H_PLAY(2),'enable','on');
    set(H_PLAY(3),'enable','on');
    %sound(signal,sample_rate);
    AXIS_PLAY(1) = timedata(F_ANALYSIS,signal,sample_rate,.06,.3,.88,.4);
    
case 2 %play
    disp('play');
    if isempty(signal) ~= 1
        %disp(sample_rate);
        sound(signal,sample_rate);
    end
    
    case 3
    disp('analyze');
    input = inputdlg({'threshold','range'},'input',1,{'.2','.5'});
    %disp(input(2));
    avgs = finds1(signal, sample_rate, str2double(input(1)), str2double(input(2)));
%    figure(AXIS_PLAY(1));
        % AXIS_PLAY(1) = timedata(F_ANALYSIS,signal,sample_rate,.06,.5,.88,.3);
    AXIS_PLAY(1) = timedata(F_ANALYSIS,signal,sample_rate,.06,0.3,.88,.3);
    hold on
    plot(signal);
    scatter(avgs(:,1)/sample_rate,avgs(:,2),'red');
    hold off
    duration_in_sec = length(signal)/sample_rate;
    duration_in_min = duration_in_sec / 60;
    beat_count = length(avgs);
    BPM = beat_count / duration_in_min;
    set(H_PLAY(4),'String',horzcat('Heart Rate:  ',num2str(BPM), ' BPM'));
    intervals = zeros(floor(length(avgs)/2)-1,1);
    j = 1;
    for i = 1:1:length(avgs)-1
        intervals(j,1) = (avgs(i+1,1) - avgs(i,1))/sample_rate;
        j = j + 1;
    end
    hrv = (1 - var(intervals))*100;
    set(H_PLAY(5),'String',horzcat('Heart Rate Variability:   ',num2str(hrv)));
 case 6
    recObj = audiorecorder(44100, 16,2); 
    disp('Start speaking.')
    set(H_PLAY(6),'String','Recording');
    recordblocking(recObj, 10);
    disp('End of Recording.');
    set(H_PLAY(6),'String','Done');
    y = getaudiodata(recObj);
    %disp(y);
    filename = inputdlg('save to','Recording',1,{'hr3.wav'});
    audiowrite(char(filename),y,44100)
    clear y;
   
end

function avgs = finds1(sig, fs, threshold, range)
    %filter
    rng default;
    Fnorm = 1000/(fs/2);
    df = designfilt('lowpassfir','FilterOrder',200,'CutoffFrequency',Fnorm);
    %grpdelay(df,2048,fs);   % plot group delay
    D = mean(grpdelay(df));
    sig = filter(df,[sig; zeros(D,1)]);
    sig = sig(D+1:end); 
    
    peaks = zeros(length(sig),2);
    i = 1;
    beat_count = 0;
    for k = 2:length(sig)-1
            if (sig(k)> sig(k-1) && sig(k) > sig(k+1) && sig(k) > threshold)
                beat_count = beat_count+1;
    %            scatter(k,sig(k));
                peaks(i,1) = k;
                peaks(i,2) = sig(k);
                i = i +1;
            end
    end
    peaks = peaks(1:beat_count,:); %gets rid of zeroes
    
    avgs = zeros(length(peaks),3);
    temp = peaks(1,1);

    j = 1;
    for i = 1:length(peaks) - 1
        if peaks(i,1) <= temp + 6000
            avgs(j,1) = avgs(j,1) + peaks(i,1);
            avgs(j,2) = avgs(j,2) + peaks(i,2);
            avgs(j,3) = avgs(j,3) + 1;
        elseif peaks(i,1) >= temp + 6000 && peaks(i,1) <= temp + range*fs
            continue
        else
            temp = peaks(i,1);
            j = j+1;
            avgs(j,1) = temp;
            avgs(j,2) = peaks(i,2);
            avgs(j,3) = 1;
        end
    end
    for k = 1:length(avgs)
            avgs(k,1) = avgs(k,1) / avgs(k,3);
            avgs(k,2) = avgs(k,2) / avgs(k,3);
    end
    avgs = avgs(1:j,1:2);
    
function createtextbox(figure1)
%CREATETEXTBOX(FIGURE1)
%  FIGURE1:  annotation figure

%  Auto-generated by MATLAB on 07-Feb-2016 19:15:25

% Create textbox
annotation(figure1,'textbox',...
    [0.254684210526315 0.89 0.686368421052632 0.0822222222222225],...
    'String','Heart/Lung Sound Recorder',...
    'LineStyle','none',...
    'FontWeight','bold',...
    'FontSize',36,...
    'FitBoxToText','off');

function createtextbox2(figure1)
%CREATETEXTBOX(FIGURE1)
%  FIGURE1:  annotation figure

%  Auto-generated by MATLAB on 07-Feb-2016 19:16:00

% Create textbox
annotation(figure1,'textbox',...
    [0.852578947368421 .00222222222222222 0.139 0.0777777777777778],...
    'String',{'By: M. D''mour, G. Gao.','Rev A: 02/08/16'},...
    'LineStyle','none',...
    'FitBoxToText','off');


function H = timedata(Fig,x,fs,left,bottom,width,height)
% This function plots time data at location specified by user
% Left, bottom, width, height are relative locations less than 1

figure(Fig);

samp_len = length(x)/fs;
delta_t = 1/fs;
t = 0:delta_t:(samp_len-delta_t);

% display the signal
H = subplot('position',[left bottom width height]);
plot(t,x), xlabel('Time [sec]'), ylabel('Amplitude')
axis([0 t(length(x)-1) -1 1 ]);
