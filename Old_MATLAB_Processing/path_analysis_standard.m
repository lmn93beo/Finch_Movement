% This script is meant only for preprocessed files 
% (output by the function preprocess_files)
% Pre-processed files have 3 columns dt, x, y with anomalies eliminated

folder = 'LB2/LB2_proc';

files = dir([folder '/*.csv']);

x_res = 320;
y_res = 180;
x_length = 14; %cm
y_length = 10; %cm

speed_agg = zeros(1, numel(files));   
dist_agg = zeros(1, numel(files));
heatmap = zeros(x_res, y_res);
cross_agg = zeros(1, numel(files));
cross_total = zeros(1, numel(files));
times_agg = zeros(1, numel(files)); 
cover_agg = zeros(1, numel(files));

% 70, 40, 100, 4 for old
% 150, 100, 200, 4 for new
% 135, 80, 190, 4
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
    times_agg(fileID) = datenum(yr, mth, date, hour, min, sec);
    
    totalT = sum(raw(:,1));
     
    dt = raw(:,1);
    x = raw(:,2);
    y = raw(:,3);
    
    
    if smooth_xy
        x = smooth(x);
        y = smooth(y);
    end
    
%     plot(x,y);
%     axis([0 x_res 0 y_res]);
%     title(strrep(files(fileID).name,'_',':'));
    
    % Find the speed between two points
    speed = find_speed(x / x_res * x_length, y / y_res & y_length, totalT);
    %[speed distance] = find_speed(x, y, totalT);
    speed_agg(fileID) = speed;
    dist_agg(fileID) = speed * totalT;
    
%     figure(1);
%     plot(x,y);
%     figure(2);
%     plot(distance);
%     waitforbuttonpress;
   
    % Find number of crossings
    jumps = find_jumps(x, boundary, left, right, margin);    
    cross_agg(fileID) = sum(jumps) / totalT;
    cross_total(fileID) = sum(jumps);
    
    fprintf('Speed = %0.3f, jumps = %d\n', speed, sum(jumps) / totalT);
    
    %waitforbuttonpress;
    
    % Heat map
    heatmap_trial = find_heat_map(x, y, dt, x_res, y_res);
    heatmap = heatmap + heatmap_trial;
    cover_agg(fileID) = sum(heatmap_trial(:) > 0);
    
%     imshow(heatmap_trial');
%     colormap jet;
%     waitforbuttonpress;
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
ndays = 5;
day1 = datenum(2016,9,19,6,0,0);
days_start = day1 + (1:ndays) - 1;
day1_end = datenum(2016,9,19,21,0,0);
days_end = day1_end + (1:ndays) - 1;

plot_days(days_start, days_end, times_agg, speed_agg, 'Speed (cm/s)', 4);
plot_days(days_start, days_end, times_agg, cross_agg * 60, 'Jumps/min', 15);
%plot_days(days_start, days_end, times_agg, cover_agg, 'Coverage', 8000);

figure(4);
imshow(heatmap' / sum(heatmap(:)) * 10000, 'InitialMagnification', 'fit');
colormap jet;
title('Heat map');
axis ij;

%% For saving data
xlswrite('movement_profiles.xlsx', [datevec(times_agg) speed_agg' cross_total', dist_agg'],...
    'LB2');
