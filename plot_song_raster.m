folder = uigetdir([],'Choose a directory with extracted songs');

files = dir([folder '/*.wav']);
timestamps = zeros(1, numel(files));

for i = 1 : numel(files)
    filename = files(i).name;
    parts = strsplit(filename, '_');
    mth = str2double(parts{3});
    day = str2double(parts{4});
    hr = str2double(parts{5});
    mins = str2double(parts{6});
    secs = str2double(parts{7});
    samples = parts{8};
    samples = str2double(samples(1:end-4));
    timestamps(i) = datenum(2016, mth, day, hr, mins, secs - samples/44100);
end


time1 = datenum(2016, mth, day, 6, 0, 0);
time2 = datenum(2016, mth, day, 21, 0, 0);
times_song = timestamps(timestamps > time1 & timestamps < time2);

%% Gather speed data
folder = 'LB21/0703';
speed_agg = [];     
times_agg = [];
files = dir([folder '/*.csv']); 
window = 30000; % 1 second

for i = 1 : numel(files)
    disp(files(i).name);
    raw = csvread([folder '/' files(i).name]);

    for j = 1 : size(raw, 1)
        if raw(j,2) == 0 && raw(j,3) == 0 %|| ...
                    %raw(i,2) > 250 && raw(i,3) > 130;
                    %raw(i,2) < 20 && raw(i,3) > 80 || ...
                    %raw(i,2) > 120
                raw(j,2) = raw(j - 1, 2);
                raw(j,3) = raw(j - 1, 3);
        end
    end
    
    x = raw(:,2);
    y = raw(:,3);
    dt = raw(:,1);
    totalT = sum(dt);
    
    [date, mth, yr, hour, min, sec] = get_date(files(i).name);
    %Tstart = datenum(yr, mth, date, hour, min, sec - totalT);
    
    nstart = 1 : window : length(x);
    nend = nstart + window - 1;
    times = cumsum(dt);
    
    for j = 1 : length(nstart)
        speed = find_speed(x(nstart(j) : nend(j)), y(nstart(j): nend(j)),...
            dt(nstart(j) : nend(j)));
        speed_agg = [speed_agg speed];
        times_agg = [times_agg datenum(yr, mth, date, hour, ...
            min, sec - totalT + times(nstart(j)))];
    end
    
    plot(x,y);
    %waitforbuttonpress;
end

speed_filt = speed_agg(times_agg > time1 & times_agg < time2);
times_filt = times_agg(times_agg > time1 & times_agg < time2);

%% Plot
hist(timestamps, 200);
hold on;
plot(times_filt - 0.03, speed_filt);
datetick('x','HH:MM');
hold on;
plot(times_song - 0.008, 50*ones(1, numel(times_song)), 'r.', 'MarkerSize', 10);



