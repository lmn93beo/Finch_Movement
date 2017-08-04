% This file is for pre-processing raw data
% Processed data is saved in another folder

folder = 'LB2/0921';
output_folder = [folder '_proc'];
debug = 0;

if ~exist(output_folder, 'dir')
    mkdir(output_folder);
end

files = dir([folder '/*.csv']);

filetype = 'dt'; % or 'abst'

% Old cam: 160 x 120
% New cam: 320 x 180
x_res = 320;
y_res = 180;

for fileID = 1:numel(files)  %[18:50 74:numel(files)]
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
        plot(x, y);
        axis([0 x_res 0 y_res]);
        axis ij;
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


