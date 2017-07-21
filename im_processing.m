%% Read all frames from video
v = VideoReader('Videos/Video 44.wmv');
numFrames = v.NumberOfFrames;
v = VideoReader('Videos/Video 44.wmv');
video = uint8(zeros(v.Height, v.Width, 3, ceil(numFrames / 10)));
for i = 1 : 10 : numFrames
    i
    %time = v.CurrentTime
    for j = 1 : 10
        try 
            frame = readFrame(v);
        catch
            disp('End of video');
        end
    end
    
    % Correct for illumination
%     background = imopen(frame,strel('disk',15));
%     frame = frame - background;
    
    video(:,:,:,ceil(i/10)) = frame;
%     imshow(frame(:,:,1));
end

numFrames = size(video, 4);

blackwhite = uint8(zeros(size(video,1), size(video,2), numFrames));
for i = 1 : numFrames
    blackwhite(:,:,i) = rgb2gray(video(:,:,:,i));
end

diff = uint8(zeros(size(video, 1), size(video, 2), numFrames));

for i = 1 : numFrames
    %frame = blackwhite(:,:,i);
    r = video(:,:,1,i);
    g = video(:,:,2,i);
    b = video(:,:,3,i);
    
    diff(:,:,i) = (r < 45 & g < 60 & b < 50);
    imshow(diff(:,:,i) * 255);
    %waitforbuttonpress;
    %imshow(frame < 100 & frame > 40);
end

%% Process each frame
se = strel('disk', 5);
h = fspecial('gaussian', 15);
for i = 1 : numFrames
    I = blackwhite(:,:,i);
    
    % Correct for illumination
    background = imopen(I,strel('disk',15));
    I2 = I - background;
    
    % Use imopen to reduce cage influence
    after = imfilter(I2, h);
    figure(1);
    imshow(after);
    
    figure(2);
    imshow(I);
    
end




%% Method: Gather difference between successive frames
diff = uint8(zeros(size(video, 1), size(video, 2), numFrames - 1));

for i = 2 : numFrames
    i
    frame1 = blackwhite(:,:,i - 1);
    frame2 = blackwhite(:,:,i);

    diff(:, :, i - 1) = imabsdiff(frame1,frame2);
    imshow(diff(:,:,i - 1) * 1.3);
    %waitforbuttonpress;
end

%% Method: Background subtraction
bgnd = blackwhite(:,:,1);
diff = uint8(zeros(size(video, 1), size(video, 2), numFrames));
for i = 1 : numFrames
    i
    frame = blackwhite(:,:,i);

    diff(:, :, i) = imabsdiff(frame,bgnd);
    imshow(diff(:,:,i));
    %waitforbuttonpress;
end

%% Thresholding
thresh = 100; %graythresh(diff);
bw = (diff >= thresh); imtool(bw(:, :, 1));

%% Identify regions
bw2 = bwareaopen(diff, 100, 8);
for i = 1 : numFrames
    imshow(bw2(:,:,i));
    %waitforbuttonpress;
end

%% Get the centroid of the largest object
centroids = zeros(numFrames - 1, 2);
for k = 1 : numFrames - 1
    disp(k);
    L = logical(bw2(:, :, k));
    s = regionprops(L, 'area', 'centroid');
    area_vector = [s.Area];
    [tmp, idx] = max(area_vector);
    if ~isempty(tmp)
        centroids(k, :) = s(idx(1)).Centroid;
    end
end

for i = 1 : numFrames - 1
    imshow(video(:,:,:,i));
    hold on;
    plot(centroids(i, 1), centroids(i, 2), 'r.', 'MarkerSize', 20);
    waitforbuttonpress;
end

%% Method: using RGB
bgnd = video(:,:,:,1);
diff = uint8(zeros(size(video, 1), size(video, 2), numFrames));

for i = 1 : numFrames
    frame = video(:,:,:,i);
    df = frame - bgnd;
    sq = df(:,:,1) .^ 2 + df(:,:,2) .^ 2 + df(:,:,3) .^ 2;
    diff(:,:,i) = sq;
    imshow(diff(:,:,i));
    %waitforbuttonpress;
end

