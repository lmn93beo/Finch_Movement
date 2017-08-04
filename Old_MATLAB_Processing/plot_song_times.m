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
    hr
end

hist(timestamps, 200);
datetick('x', 'HHPM');