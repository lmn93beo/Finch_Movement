function plot_days(days_start, days_end, time_pts, series, plot_name,...
    max_range)

% Sort time series in increasing order
[time_pts, idx] = sort(time_pts);
series = series(idx);

assert(numel(days_start) == numel(days_end));
ndays = numel(days_start);
figure();
title(plot_name);
for i = 1:ndays
    if i == 1
        times_of_interest = time_pts < days_end(1);
    elseif i == numel(days_start)
        times_of_interest = time_pts > days_start(end);
    else
        times_of_interest = time_pts >= days_start(i) & ...
            time_pts < days_end(i);
    end

    subplot(ndays,1,i);
%     scatter(time_pts(times_of_interest), series(times_of_interest),...
%         25, 'filled');
%     hold on;
    plot(time_pts(times_of_interest), series(times_of_interest));
    hold on;
%    [peakheight, peakid] = findpeaks(series(times_of_interest),'MinPeakProminence',0.5);
%    lst = time_pts(times_of_interest);
%    scatter(lst(peakid), peakheight);
    
    ylabel(plot_name);
    ylim([0 max_range])
    xlim([days_start(i) days_end(i)])
    datetick('x','HHPM','keeplimits');
end

hold off;