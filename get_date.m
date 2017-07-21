function [date, mth, yr, hour, min, sec] = get_date(filename)

parts = strsplit(filename, '_');
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