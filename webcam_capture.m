clear all;

% Initialize the camera
camList = webcamlist;
cam = webcam(1);
root = 'LB21t0707';  %Root of file names

%preview(cam);

% Set up some variables for log keeping
BUFFER_SIZE = 100;        % How many frames to record before writing to log
centroids = zeros(BUFFER_SIZE, 2);
times = zeros(BUFFER_SIZE, 1);
areas = zeros(BUFFER_SIZE, 1);
timestamps = zeros(BUFFER_SIZE, 3);
i = 1;
tic;

finish = 0;
debug = 0;
set(gcf,'CurrentCharacter','@'); % set to a dummy character
r_threshold =55;
g_threshold = 80;
b_threshold = 90;

% Set up a sound to be played
sig = 1 : 44100;
sig = sin(sig/3);

while ~finish %toc < 30
    % Capture a raw frame
    img = snapshot(cam);
    img = imresize(img, 0.5);
    
    if mod(i,2000) == 0
        close all
    end
    
    % Threshold
    diff = img(:,:,1) < r_threshold & ...
        img(:,:,2) < g_threshold & ...
        img(:,:,3) < b_threshold;
    
    % Remove small areas
    bw2 = bwareaopen(diff, 190, 8);
 
    % Get centroid
    L = logical(bw2);
    s = regionprops(L, 'area', 'centroid');
    
    area_vector = [s.Area];
    [tmp, idx] = max(area_vector);
    if ~isempty(tmp)
        centroids(i,:) = s(idx(1)).Centroid;
        areas(i,:) = s(idx(1)).Area;
    end
    
    times(i) = toc;
    currtime = clock;
    timestamps(i,:) = currtime(4:end);
    tic;
    
    i = i + 1;
    
    % Show the image (for debugging)
    if debug == 1
        imshow(img);
        hold on;
        plot(centroids(i-1, 1), centroids(i-1, 2), 'r.', 'MarkerSize', 20);
    elseif debug == 2
        imshow(bw2);
        hold on;
        plot(centroids(i-1, 1), centroids(i-1, 2), 'r.', 'MarkerSize', 20);
    end
    
    if i > BUFFER_SIZE
        % Write the data
        currtime = strrep(datestr(now), ':', '_');
        filename = [root '_' currtime '.csv']
        csvwrite(filename, [times centroids areas timestamps]);
        
        % Reset some variables
        i = 1;
        % Play a sound
        sound(sig, 44100);
        clear centroids times;
        centroids = zeros(BUFFER_SIZE, 2);
        times = zeros(BUFFER_SIZE, 1);
    end
    
    k=get(gcf,'CurrentCharacter');
    if k~='@' % has it changed from the dummy character?
        disp('(q)-quit, (t)-toggle, (r/e)-red, (g/f)-green, (b/v)-blue');
        set(gcf,'CurrentCharacter','@'); % reset the character
        % now process the key as required
        if k=='q'
            finish=true
        elseif k == 't'
            debug = mod(debug + 1, 3);
        elseif k == 'r'
            r_threshold = r_threshold + 5;
        elseif k == 'g'
            g_threshold = g_threshold + 5;
        elseif k == 'b'
            b_threshold = b_threshold + 5;
        elseif k == 'e'
            r_threshold = r_threshold - 5;
        elseif k == 'f'
            g_threshold = g_threshold - 5;
        elseif k == 'v'
            b_threshold = b_threshold - 5;
        end
        fprintf('r = %d, g = %d, b = %d\n', r_threshold,...
            g_threshold, b_threshold);
        
    end
end

% Write the data one last time
currtime = strrep(datestr(now), ':', '_');
filename = [root '_' currtime '.csv']
csvwrite(filename, [times centroids areas timestamps]);
