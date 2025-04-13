%% START & CLEANUP
clearvars; close all; clc;

%% LOAD EEG SIGNALS FROM A VOLUNTEER
filename = 'v01.mat';
load(filename);  % Load EEG variable, EEGLab format

%% DEFINITIONS
num_events = numel(EEG.event);  % 960 --> 480 pairs of fixation cross (c) followed by task
                                %         First 120 trials are motor execution
                                %         Next 360 are motor imagery. Each trial is labeled:
                                %          - b indicates resting (baseline)
                                %          - r indicates right
                                %          - l indicates left
Fs = EEG.srate;  % 125 Hz
signals = detrend(EEG.data(1:15,:)', 'constant');  % 16 columns (but ch 16 unused)
% Ignore EEG labels in the mat-file. These are the channels in order:
ch_names = {'F7','F3','Fz','F4','F8','T3','C3','Cz','C4','T4','P7','P3','Pz','P4','P8'};
first_trial = 121;


%% FILTER DEFINITIONS
% Mu+Beta filter (8 to 30 Hz)
Fstop1 = 7.9;         % First Stopband Frequency
Fpass1 = 8;           % First Passband Frequency
Fpass2 = 30;          % Second Passband Frequency
Fstop2 = 30.1;        % Second Stopband Frequency
Astop1 = 20;          % First Stopband Attenuation (dB)
Apass  = 0.1;         % Passband Ripple (dB)
Astop2 = 20;          % Second Stopband Attenuation (dB)
match  = 'passband';  % Band to match exactly
h  = fdesign.bandpass(Fstop1, Fpass1, Fpass2, Fstop2, Astop1, Apass, Astop2, Fs);
mubeta_filter = design(h, 'cheby2', 'MatchExactly', match, 'SystemObject', true);
reorder(mubeta_filter, 'up');


%% EPOCHING TRIALS AND CONCATENATION
mi_right = [];
mi_left = [];
mi_rest = [];
mi_right_std = [];
mi_left_std = [];
mi_rest_std = [];

for ev = first_trial*2 : 2 : num_events
    start_sample = EEG.event(ev).latency;
    stop_sample = EEG.event(ev).latency+2*Fs-1;
    
    % Display trial latency
    fprintf('Ev %3d [%s]--> %6d (%8.3f)\n', ...
        ev, upper(EEG.event(ev).type), start_sample, start_sample/Fs);
    
    trial = detrend(signals(start_sample:stop_sample, :), 'constant');
    pad_trial = [flipud(trial); trial; flipud(trial)];
    filt_pad_trial = filtfilt(mubeta_filter.SOSMatrix, mubeta_filter.ScaleValues, pad_trial);
    filt_trial = filt_pad_trial(size(trial,1)+1:2*size(trial,1), :);

    % Plot to check that filtered signals look OK
    if ev == first_trial*2
        figure; hold on; box on;
        plot(1/Fs:1/Fs:length(trial(:,1))/Fs, trial(:, strcmp(ch_names, 'Cz')));
        plot(1/Fs:1/Fs:length(trial(:,1))/Fs, filt_trial(:, strcmp(ch_names, 'Cz')));
        legend('Raw Cz (detrended)', 'Filtered Cz');
        ylabel('amplitude (\muV)', 'Interpreter','tex');
        xlabel('time (s)')
        title(['EEG (' filename ')'])
        axis tight;
    end

    % Calculations performed trial by trial:
    %  - Features (for example, standard deviation of channel Cz):
    %  - Concatenate trial to corresponding matrix (for example for later SCP calculation)
    switch EEG.event(ev).type
        case 'r'
            mi_right_std = [mi_right_std; std(filt_trial(:,strcmp(ch_names, 'Cz')))];
            mi_right = [mi_right; filt_trial];
        case 'l'
            mi_left_std = [mi_left_std; std(filt_trial(:,strcmp(ch_names, 'Cz')))];
            mi_left = [mi_left; filt_trial];
        case 'b'
            mi_rest_std = [mi_rest_std; std(filt_trial(:,strcmp(ch_names, 'Cz')))];
            mi_rest = [mi_rest; filt_trial];
        otherwise
            error('This should not happen!')
    end
end
 
%% COMBINE VECTORS INTO TABLE & EXPORT CSV
% Use only 4 values of each task (instead of 120), just for the example:
df = table([mi_rest_std(1:4); mi_left_std(1:4); mi_right_std(1:4)] , ...
            [repmat("rest",4,1); repmat("left",4,1); repmat("right",4,1)], ...
           'VariableNames', {'std_8_30', 'mi_task'});
writetable(df, 'features.csv')