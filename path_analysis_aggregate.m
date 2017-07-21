folder = '2CW305_proc';

files = dir([folder '/*.csv']);
filetype = 'dt';

y_res = 180;
x_res = 240;
x_length = 11.5; %cm

speed_agg = zeros(1, numel(files));     
heatmap = zeros(x_res, y_res);
cross_agg = zeros(1, numel(files)); 
times_agg = zeros(1, numel(files)); 

boundary = 130;
left = 70;
right = 190;
margin = 4;
smooth_xy = 1;

%% Analyze files (old & new combined)
for fileID = 1 : numel(files) %[18:50 74:numel(files)]
    fprintf('Processing file %d of %d\n', fileID, numel(files));
    raw = csvread([folder '/' files(fileID).name]);
    
    % Parse date info from filename
    [date, mth, yr, hour, min, sec] = get_date(files(fileID).name);
    times_agg(fileID) = datenum(yr, mth, date, hour, min, sec);
    
    if strcmp(filetype, 'dt')
        totalT = sum(raw(:,1));
    elseif strcmp(filetype, 'abst')
        totalT = raw(end,1);
    end

    % Discard rows with (0,0)
    raw(raw(:,2) == 0 & raw(:,3) == 0,:) = [];
    %raw(raw(:,2) < 10,:) = [];
    raw(raw(:,2) > 240,:) = [];

    x = raw(:,2);
    y = raw(:,3);
    
    if smooth_xy
        x = smooth(x);
        y = smooth(y);
    end
    
    if strcmp(filetype, 'abst')
        t1 = raw(1:end-1, 1);
        t2 = raw(2:end, 1);
        dt = t2 - t1;
    elseif strcmp(filetype,'dt')
        t2 = cumsum(raw(2:end, 1));
        t1 = cumsum(raw(1:end-1, 1));
        dt = raw(2:end, 1);
    end

    % Find the speed between two points
    speed = find_speed(x, y, totalT);
    %plot(x,y);
    disp(files(fileID).name);
    %waitforbuttonpress;
    speed_agg(fileID) = speed / x_res * x_length;
   
    % Find number of crossings
    jumps = find_jumps(x, boundary, left, right, margin);    
    cross_agg(fileID) = sum(jumps) / totalT;
    
    % Heat map
    heatmap = heatmap + find_heat_map(x, y, dt, x_res, y_res);
end

%% Plot the data (not split)
figure(1);
plot(times_agg,speed_agg);
title('Speed');
xlabel('Time')
ylabel('Speed (pix/sec)')
datetick('x','HHPM');

figure(2);
imshow(heatmap' / max(heatmap(:)) * 255, 'InitialMagnification', 'fit');
colormap jet;
title('Heat map');
axis ij;

figure(3);
plot(times_agg, cross_agg * 60);
title('Number of jumps per minute');
datetick('x','HHPM');

%% Save some parameters
times_agg1 = times_agg;
speed_agg1 = speed_agg;
cross_agg1 = cross_agg;

%% Split by day
ndays = 5;
day1 = datenum(2016,7,1,6,0,0);
days_start = day1 + (1:ndays) - 1;
day1_end = datenum(2016,7,1,21,0,0);
days_end = day1_end + (1:ndays) - 1;

plot_days(days_start, days_end, times_agg, speed_agg, 'Speed');
plot_days(days_start, days_end, times_agg, cross_agg * 60, 'Jumps');

figure(3);
imshow(heatmap' / max(heatmap(:)) * 255, 'InitialMagnification', 'fit');
colormap jet;
title('Heat map');
axis ij;


