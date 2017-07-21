folder = 'LB21';

files = dir([folder '/*.csv']);

speed_agg = [];     
heatmap = zeros(180, 120);
times_agg = [];
cross_agg = [];
cross_times = [];
nbins = 10; %How many time bins per file (~17 minutes)

%% New file format
for fileID = 1 : numel(files) %[18:50 74:numel(files)]
    fprintf('Processing file %d of %d\n', fileID, numel(files));
    raw = csvread([folder '/' files(fileID).name]);
    parts = strsplit(files(fileID).name, '_');
    part2 = parts{2};
    part2split = strsplit(part2, ' ');
    datestr = datetime(part2split{1});
    
    date = day(datestr);
    mth = month(datestr);
    yr = year(datestr);
    hour = str2double(part2(end-1:end));
    min = str2double(parts{3});
    sec = parts{4};
    sec = str2double(sec(1:2));

    % Discard rows with (0,0)
    raw(raw(:,2) == 0 & raw(:,3) == 0,:) = [];
    %raw(raw(:,2) < 10,:) = [];
    %raw(raw(:,2) > 130,:) = [];

    x = raw(:,2);
    y = raw(:,3);

    % Find the speed between two points
    start_pt = raw(1:end-1, 2:3);
    end_pt = raw(2:end, 2:3);
    ds_squared = (start_pt - end_pt) .^ 2;
    distance = sqrt(sum(ds_squared, 2));
    
    % Divide distance vector into 10 subvectors and find the sum
    startID = floor(linspace(1, numel(distance), nbins)); 
    endID = startID(2:end) - 1;
    startID = startID(1 : end-1);
    speed = zeros(1, length(startID));
    for i = 1 : length(startID)
        speed(i) = sum(distance(startID(i):endID(i))) / ...
            sum(raw(startID(i):endID(i), 1));
    end
           
    speed_agg = [speed_agg speed];
    
    % Find number of crossings
    boundary = 70;
    crossings = (start_pt(:,1) > boundary & end_pt(:,1) < boundary) | ...
                (start_pt(:,1) < boundary & end_pt(:,1) > boundary);
    jump_fine = zeros(1, length(startID));
    for i = 1 : length(startID)
        jump_fine(i) = sum(crossings(startID(i):endID(i))) / ...
            sum(raw(startID(i):endID(i), 1));
    end
    
%     possible_jump = find(crossings);
%     possible_jump(possible_jump <= 4 | possible_jump >= numel(x) - 4) = [];
%     jumps = x(possible_jump - 4) < 40 & x(possible_jump + 4) > 100 | ...
%         x(possible_jump + 4) < 40 & x(possible_jump - 4) > 100;
    
    cross_agg = [cross_agg jump_fine];
    cross_time = zeros(1, length(startID));
    
    for i = 1 : length(startID)
        cross_time(i) = datenum(yr, mth, date, hour, min, ...
            sec - sum(raw(startID(i):end,1)));
    end
    
    cross_times = [cross_times cross_time];
    
%     plot(cross_times,speed_agg);
%     title(files(fileID).name);
%     waitforbuttonpress;
    
    % Heat map
    for i = 1 : (numel(x) - 1)
        x_coord = ceil(x(i));
        y_coord = ceil(y(i));
        heatmap(x_coord, y_coord) = heatmap(x_coord, y_coord) + (raw(i+1,1) - raw(i,1));
    end
end

%% Plot the data (not split)
figure(1);
plot(cross_times,speed_agg);
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
plot(cross_times, cross_agg * 60);
title('Number of jumps per minute');
datetick('x','HHPM');

%% Split by day
% day1 = datenum('06/28/2016','mm/dd/yyyy');
% day2 = datenum('06/29/2016','mm/dd/yyyy');
% day3 = datenum('06/30/2016','mm/dd/yyyy');
% day4 = datenum('07/1/2016','mm/dd/yyyy');
% day5 = datenum('07/2/2016','mm/dd/yyyy');

day1 = datenum(2016,7,1,6,0,0);
day2 = datenum(2016,7,2,6,0,0);
day3 = datenum(2016,7,3,6,0,0);
day4 = datenum(2016,7,4,6,0,0);
day5 = datenum(2016,7,5,6,0,0);

day1_end = datenum(2016,7,1,21,0,0);
day2_end = datenum(2016,7,2,21,0,0);
day3_end = datenum(2016,7,3,21,0,0);
day4_end = datenum(2016,7,4,21,0,0);
day5_end = datenum(2016,7,5,21,0,0);


times1 = cross_times < day1_end;
times2 = cross_times >= day2 & cross_times < day2_end;
times3 = cross_times >= day3 & cross_times < day3_end;
times4 = cross_times >= day4;

figure(1);
title('Speed');
subplot(4,1,1);
plot(cross_times(times1),speed_agg(times1));
ylim([0 200])
datetick('x','HHPM');
xlim([day1 day1_end])

subplot(4,1,2);
plot(cross_times(times2),speed_agg(times2));
ylabel('Speed (pix/sec)')
ylim([0 200])
datetick('x','HHPM');
xlim([day2 day2_end])

subplot(4,1,3);
plot(cross_times(times3),speed_agg(times3));
xlabel('Time')
ylim([0 200])
datetick('x','HHPM');
xlim([day3 day3_end])

subplot(4,1,4);
plot(cross_times(times4),speed_agg(times4));
xlabel('Time')
ylim([0 300])
datetick('x','HHPM');
xlim([day4 day4_end])
set(gca,'Xtick',1:2)

figure(2);
imshow(heatmap' / max(heatmap(:)) * 5, 'InitialMagnification', 'fit');
colormap jet;
title('Heat map');
axis ij;

figure(3);
title('Number of jumps per minute');
subplot(4,1,1);
plot(cross_times(times1), cross_agg(times1) * 60);
ylim([0 150]);
datetick('x','HHPM');
xlim([day1 day1_end])

subplot(4,1,2);
plot(cross_times(times2), cross_agg(times2) * 60);
ylim([0 150]);
ylabel('Jumps/min');
datetick('x','HHPM');
xlim([day2 day2_end])

subplot(4,1,3);
plot(cross_times(times3), cross_agg(times3) * 60);
ylim([0 150]);
datetick('x','HHPM');
xlim([day3 day3_end])

subplot(4,1,4);
plot(cross_times(times4), cross_agg(times4) * 60);
ylim([0 150]);
datetick('x','HHPM');
xlim([day4 day4_end])
set(gca,'Xtick',1:2)



