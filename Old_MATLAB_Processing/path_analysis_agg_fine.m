%% Read files
folder = '2CW312/2CW312_proc';

speed_agg = [];     
heatmap = zeros(360, 180);
cross_agg = [];
times_agg = [];
filetype = 'dt';
nbins = 5; %How many time bins per file (~17 minutes)

boundary = 70;
left = 40;
right = 100;
margin = 4;
smooth_xy = 1;


files = dir([folder '/*.csv']);   

for fileID = 1 : numel(files) %[18:50 74:numel(files)]
    fprintf('Processing file %d of %d\n', fileID, numel(files));
    raw = csvread([folder '/' files(fileID).name]);
    
    % Parse date info from filename
    fname = files(fileID).name;
    [date, mth, yr, hour, min, sec] = get_date(fname(6:end));
    
    % Discard rows with (0,0)
    raw(raw(:,2) == 0 & raw(:,3) == 0,:) = [];
    raw(raw(:,2) < 10,:) = [];
    raw(raw(:,2) > 270,:) = [];

    x = raw(:,2);
    y = raw(:,3);
    
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
    [~, distance] = find_speed(x, y, dt);
   
    % Divide distance vector into 10 subvectors and find the sum
    startID = floor(linspace(1, numel(distance), nbins)); 
    endID = startID(2:end) - 1;
    startID = startID(1 : end-1);
    speed = zeros(1, length(startID));
    for i = 1 : length(startID)
        speed(i) = sum(distance(startID(i):endID(i))) / ...
            sum(dt(startID(i):endID(i)));
    end
          
    speed_agg = [speed_agg speed];

    % Find number of crossings
    boundary = 70;
    [~, crossings] = find_jumps(x, boundary, left, right, margin);
    jump_fine = zeros(1, length(startID));
    for i = 1 : length(startID)
        jump_fine(i) = sum(crossings(startID(i):endID(i))) / ...
            sum(dt(startID(i):endID(i)));
    end
    
    
    cross_agg = [cross_agg jump_fine];
    cross_time = zeros(1, length(startID));
    for i = 1 : length(startID)
        cross_time(i) = datenum(yr, mth, date, hour, min, ...
            sec - sum(dt(startID(i):end)));
    end
    
    times_agg = [times_agg cross_time];

    % Heat map
    %heatmap = heatmap + find_heat_map(x, y, dt, x_res, y_res);
end

%% Plot the data (not split)
figure(1);
plot(times_agg,speed_agg);
title('Speed');
xlabel('Time')
ylabel('Speed (pix/sec)')
datetick('x','HHPM');

figure(2);
imshow(heatmap' / max(heatmap(:)) * 100, 'InitialMagnification', 'fit');
colormap jet;
title('Heat map');
axis ij;

figure(3);
plot(times_agg, cross_agg * 60);
title('Number of jumps per minute');
datetick('x','ddmm');

%% Split by day
ndays = 5;
day1 = datenum(2016,7,1,6,0,0);
days_start = day1 + (1:ndays) - 1;
day1_end = datenum(2016,7,1,21,0,0);
days_end = day1_end + (1:ndays) - 1;

plot_days(days_start, days_end, times_agg, speed_agg, 'Speed');
plot_days(days_start, days_end, times_agg, cross_agg, 'Jumps');

figure(3);
imshow(heatmap' / max(heatmap(:)) * 255, 'InitialMagnification', 'fit');
colormap jet;
title('Heat map');
axis ij;

