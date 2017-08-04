%% Animal info
plot_type = 'cum_dist'; % 'cum_dist' or 'peaks'
source = 'movement_profiles.xlsx';

animal = '2CW100w';
day_size = 24;

mean_profile = zeros(1, day_size);
day_start = [9 13];


%% Process
figure;
hold on;
raw = xlsread(source, animal);
% Read in the speed/distance info
timestamps = datenum(raw(:,1:6));
speed = raw(:,7);
jumps = raw(:,8);
dist = raw(:,9);

for i = 1 : size(day_start, 1)
    i
    single_profile = zeros(1, day_size);
    for j = 1 : day_size
        starting = datenum(2016, day_start(i, 1), day_start(i, 2), j, 0, 0);
        ending = datenum(2016, day_start(i, 1), day_start(i, 2), j + 1, 0, 0);

        times = timestamps(timestamps > starting & timestamps < ending);
        %speed = speed(timestamps > starting & timestamps < ending);
        jumps = jumps(timestamps > starting & timestamps < ending);
        dist_hour = dist(timestamps > starting & timestamps < ending);
        
        %single_profile(j) = sum(dist_hour);
        single_profile(j) = sum(jumps);
    end
    mean_profile = mean_profile + single_profile;
    plot(datenum(2016, 1, 1, 1:24, 0, 0), cumsum(single_profile));
end

plot(datenum(2016, 1, 1, 1:24, 0, 0), cumsum(mean_profile) / size(day_start, 1));
legend({'LB21 d1', 'LB21 d2', 'LB21 d3', 'LB21 d4', 'd5', 'd6', 'd7', 'd8', 'mean'});

datetick('x', 'HHPM');


%% Save data
xlswrite('average_profile.xlsx', cumsum(mean_profile)' / size(day_start, 1), ...
    animal);

