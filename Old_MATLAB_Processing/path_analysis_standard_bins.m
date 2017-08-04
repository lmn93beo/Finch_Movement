% This script is meant only for preprocessed files 
% (output by the function preprocess_files)
% Pre-processed files have 3 columns dt, x, y with anomalies eliminated

folder = '2CW317/2CW317_proc';

files = dir([folder '/*.csv']);

x_res = 320;
y_res = 180;
x_length = 14; %cm
y_length = 10; %cm

nbins = 1;

speed_agg = zeros(1, nbins * numel(files));     
heatmap = zeros(x_res, y_res);
cross_agg = zeros(1, nbins * numel(files)); 
times_agg = zeros(1, nbins * numel(files)); 
cover_agg = zeros(1, nbins * numel(files));
dist_agg = zeros(1, nbins * numel(files));

boundary = 135;
left = 80;
right = 190;
margin = 4;
smooth_xy = 0;



%% Analyze files (old & new combined)
for fileID = 1 : numel(files) %[18:50 74:numel(files)]
    fprintf('Processing file %d of %d\n', fileID, numel(files));
    raw = csvread([folder '/' files(fileID).name]);
    
    % Parse date info from filename
    [date, mth, yr, hour, min, sec] = get_date(files(fileID).name(6:end));
    files_vec = (fileID - 1) * nbins + (1 : nbins);
    
    totalT = sum(raw(:,1));
    times_agg(files_vec) = datenum(yr, mth, date, hour, min, ...
        sec - totalT / nbins * (nbins : -1 : 1));
         
    dt = raw(:,1);
    x = raw(:,2);
    y = raw(:,3);
    
    if smooth_xy
        x = smooth(x);
        y = smooth(y);
    end
    
    startID = floor(linspace(1, numel(x), nbins + 1)); 
    endID = startID(2:end) - 1;
    
    for i = 1 : nbins
        id = (fileID - 1) * nbins + i;
        
        x_bin = x(startID(i) : endID(i));
        y_bin = y(startID(i) : endID(i));
        
        % Find the speed between two points
        speed = find_speed(x_bin / x_res * x_length,...
            y_bin / y_res & y_length, totalT / nbins);
        speed_agg(id) = speed;
        dist_agg(id) = speed * totalT / nbins;

        % Find number of crossings
        jumps = find_jumps(x_bin, boundary, left, right, margin);    
        cross_agg(id) = sum(jumps) / (totalT / nbins);

        fprintf('Speed = %0.3f, jumps = %d\n', speed, sum(jumps));

        % Heat map
        heatmap_trial = find_heat_map(x_bin, y_bin, dt, x_res, y_res);
        heatmap = heatmap + heatmap_trial;
        cover_agg(id) = sum(heatmap_trial(:) > 0) / x_res / y_res;
    end
end

%% Plot the data (not split)
figure(1);
plot(times_agg,speed_agg);
title('Speed');
xlabel('Time')
ylabel('Speed (cm/sec)')
datetick('x','HHPM');

figure(2);
imshow(heatmap' / max(heatmap(:)) * 1000, 'InitialMagnification', 'fit');
colormap jet;
title('Heat map');
axis ij;

figure(3);
plot(times_agg, cross_agg * 60);
title('Number of jumps per minute');
datetick('x','HHPM');

%% Split by day
ndays = 6;
day1 = datenum(2016,7,20,6,0,0);
days_start = day1 + (1:ndays) - 1;
day1_end = datenum(2016,7,20,21,0,0);
days_end = day1_end + (1:ndays) - 1;

% Find the peaks in speed
[~, peakid] = findpeaks(speed_agg,'MinPeakProminence',0.5);
peakdata = zeros(1, length(speed_agg));
peakdata(peakid) = 1;
fprintf('Number of peaks = %d\n', sum(peakdata));

plot_days(days_start, days_end, times_agg, speed_agg, 'Speed (pix/s)', 4);
plot_days(days_start, days_end, times_agg, cross_agg * 60, 'Jumps/min', 20);
%plot_days(days_start, days_end, times_agg, cover_agg, 'Coverage', 0.2);

figure(4);
imshow(heatmap' / 2, 'InitialMagnification', 'fit');
colormap jet;
title('Heat map');
axis ij;

%% Save the data
xlswrite('movement_profiles_bins1.xlsx', ...
    [datevec(times_agg) speed_agg' cross_agg' * 60, dist_agg', peakdata'],...
    '2CW317');


