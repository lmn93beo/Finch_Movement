% This file is for pre-processing raw data
% Processed data is saved in another folder

folder = '2CW312/0710';
%output_folder = '2CW305';

files = dir([folder '/*.csv']);

filetype = 'dt'; % or 'abst'
hops = [];
hop_speed = [];
boundary = 130;
left = 70;
right = 190;
margin = 4;

x_res = 320;
y_res = 180;


for fileID = 1 : numel(files) %[18:50 74:numel(files)]
    raw = csvread([folder '/' files(fileID).name]);

    % Discard rows with (0,0)
    %raw(raw(:,2) == 0 & raw(:,3) == 0,:) = [];
    %raw(raw(:,2) < 10,:) = [];
    %raw(raw(:,2) > 240,:) = [];

    x = raw(:,2);
    y = raw(:,3);
    
    figure(3);
    plot(y);
    
%     x = smooth(x);
%     y = smooth(y);
    

    % Plot trajectory
    figure(1);
    subplot(1,2,1); 
    plot(x, y);
    axis([0 x_res 0 y_res]);
    axis ij;
    title('Trajectory');
    subplot(1,2,2);
    scatter(x, y);
    axis([0 x_res 0 y_res]);
    axis ij;
    title('Positions');

    % Find the speed between two points
    if strcmp(filetype, 'abst')
        t1 = raw(1:end-1, 1);
        t2 = raw(2:end, 1);
        dt = t2 - t1;
    elseif strcmp(filetype,'dt')
        t2 = cumsum(raw(2:end, 1));
        t1 = cumsum(raw(1:end-1, 1));
        dt = raw(2:end, 1);
    end
    [~,distance] = find_speed(x, y, dt); 
    speed = distance ./ dt;

    figure(2);
    plot(t1, speed);
    title([strrep(files(fileID).name, '_', ':') '. Speed']);
    xlabel('Time (secs)')
    ylabel('Speed (pix/sec)')
    ylim([0 500])
    datetick('x','hh:mm')
    
    % Find number of crossings
    [jumps, crossings] = find_jumps(x, boundary, left, right, margin);
    fprintf('File: %s',files(fileID).name);
    fprintf('Number of crossings = %d, number of jumps = %d\n',...
        sum(crossings), sum(jumps));

    % Heat map
%     heatmap = find_heat_map(x, y, dt, x_res, y_res);
%     figure(3);
%     imshow(heatmap' * 5, 'InitialMagnification', 'fit');
%     colormap jet;
%     title('Heat map');
%     axis ij;
    
    % Histogram of hop speed
%     hop_length = abs(x(max(possible_jump - 4,1)) - x(min(possible_jump + 4,...
%         numel(x))));
%     hop_time = abs(t1(max(possible_jump - 4,1)) - t1(min(possible_jump + 4,...
%         numel(t1))));
%     hops = [hops; hop_length];
%     hop_speed = [hop_speed; speed(possible_jump)]; %hop_length ./ hop_time];
%     figure(4);
%     hist(speed(possible_jump));
    %xlim([0,100]);
    %pause(1);
    %csvwrite([output_folder '/proc_' files(fileID).name], [dt x y]);
    
    
    waitforbuttonpress;
end

% hist(hop_speed, 70);


