% This file is for pre-processing raw data
% Processed data is saved in another folder

folder = '2CW317/0721';
output_folder = [folder '_proc'];
debug = 1;
showplot = 1;

if ~exist(output_folder, 'dir')
    mkdir(output_folder);
end

files = dir([folder '/*.csv']);

filetype = 'dt'; % or 'abst'

% Old cam: 160 x 120
% New cam: 320 x 180
x_res = 320;
y_res = 180;

for fileID = 12  %[18:50 74:numel(files)]
    fprintf('Processing file %d of %d\n', fileID, numel(files));
    raw = csvread([folder '/' files(fileID).name]);

    % Discard rows with (0,0).
    % Go down the rows, if a row has (0, 0), copy the entry from
    % the row above it
    if strcmp(filetype, 'dt')
        if raw(1,2) == 0 && raw(1,3) == 0
            raw(1,2) = x_res / 2;
            raw(1,3) = y_res / 2;
        end
        
        for i = 2 : size(raw, 1)
            if raw(i,2) == 0 && raw(i,3) == 0 ...
                    %|| raw(i,2) > 230 && raw(i,3) > 120
                    %|| raw(i,2) > 140 && raw(i,3) > 100 %&& raw(i,3) > 130;
                    %raw(i,2) < 20 && raw(i,3) > 80 || ...
                    %raw(i,2) > 120
                raw(i,2) = raw(i - 1, 2);
                raw(i,3) = raw(i - 1, 3);
                %raw(i,4) = raw(i - 1, 4);
            end
        end
    elseif strcmp(filetype, 'abst')
        raw(raw(:,2) == 0 & raw(:,3) == 0,:) = [];
        %raw(raw(:,2) < 10,:) = [];
    end
    
    % Convert from pixels to actual dimension in cm  
    if strcmp(filetype, 'dt')
        x = raw(:,2); 
        y = raw(:,3); 
        dt = raw(:,1);
    else
        x = raw(2:end,2);
        y = raw(2:end,3);
        dt = raw(2:end, 1) - raw(1: end - 1, 1);
    end
        
    
    %processed = filter_path(raw, 100);
    
    if size(raw, 2) > 4
        timestamps = raw(:, 5:7);
    else
        timestamps = [];
    end
    
    %x = ceil(x / 160 * 360);
    %y = ceil(y / 120 * 180);
    
    if debug
        % Plot trajectory
        figure(1);
        c = linspace(1,10,21);
        jump_speeds = [];
        for i = 1:length(x)
            if i > 20
                if showplot
                    subplot(2,1,1);
                    scatter(x(i-20 : i), y(i-20 : i), [], c, 'filled');
                    axis([0 x_res 0 y_res]);
                    axis ij;
                end
                

                dx = x(i-19 : i) - x(i-20 : i-1);
                dy = y(i-19 : i) - y(i-20 : i-1);
                dtime = dt(i-19 : i);
                dtravelled = sqrt(dx .^ 2 + dy .^ 2) ./ dtime;
                if showplot
                    subplot(2,1,2);   
                    plot(1:20, dtravelled ./ dtime);
                    ylim([0 30000]);
                    xlabel('Speed (pix)');
                    ylabel('Time');
                    pause(1/30);
                end
                
                if (x(i) > 150 && x(i-1) < 150 || x(i) < 150 && x(i-1) > 150) ...
                       && dtravelled(end) > 20
                   if showplot
                        subplot(2,1,1);
                        set(gca,'Color',[1 0 0]);
                   end
                    %pause(0.1);
                    disp(dtravelled(end) / dt(i));
                    jump_speeds = [jump_speeds dtravelled(end) / dt(i)];
                end
                 axis([0 20 1 30000]);
                ylim([1 400]);
            else
                subplot(2,1,1);
                scatter(x(1 : i), y(1 : i));
                axis([0 x_res 0 y_res]);
                axis ij;
            end
            
             
        end
%         axis([0 x_res 0 y_res]);
%         axis ij;
        %title('Trajectory');
        title(['File name: ' strrep(files(fileID).name, '_', ':')]);

        % Heat map
        heatmap = find_heat_map(x, y, dt, x_res, y_res);
        figure(2);
        imshow(heatmap' * 5, 'InitialMagnification', 'fit');
        colormap jet;
        title('Heat map');
        axis ij;
        
    end
     
    if debug
        waitforbuttonpress;
    else
        if ~exist([output_folder '/proc_' files(fileID).name], 'file')
            csvwrite([output_folder '/proc_' files(fileID).name], ...
                [dt x y timestamps]);
        else
            disp('File exists!')
        end 
    end
end


