[filename, dir] = uigetfile('*.xlsx', 'Choose an excel file with the timestamps');
raw = xlsread([dir '/' filename]);

timestamps = datenum(2016, raw(:,1), raw(:,2), raw(:,3), raw(:,4), ...
    raw(:,5) - raw(:,6) / 44100);

hist(timestamps, 200);
datetick('x', 'HHPM');