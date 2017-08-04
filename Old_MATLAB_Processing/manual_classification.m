function manual_classification()
global i folder filelist
folder = uigetdir;
cd(folder);
filelist = dir([folder '\*.wav']);

% Turn off warnings
id = 'images:initSize:adjustingMag';
warning('off', id);


if ~exist([folder '\Good_examples'], 'dir')
    mkdir(folder, 'Good_examples');
end

if ~exist([folder '\Bad_examples'], 'dir')
    mkdir(folder, 'Bad_examples');
end

i = 1;
[TS, fs] = audioread([folder '/' filelist(i).name]);

% Show the sonogram
[sonogram_im,~,~]=zftftb_pretty_sonogram(TS, fs, ...
    'len', 34, 'overlap', 33, 'clipping', [-3 2], 'filtering', 300);

figure('KeyPressFcn', @(src,evnt)onKeyPressRelease(evnt,'press'));
imshow(flip(sonogram_im, 1));
colormap hot;
end

function onKeyPressRelease(evnt, ~)
global i folder filelist


if i <= length(filelist)
    status = repmat('-', 1, 100);
    progress = floor(i / length(filelist) * 100);
    fprintf('Progress: %d%%\n', progress);
    status(1 : progress) = '=';
    disp(status);
    
    disp(filelist(i).name);
    if strcmp(evnt.Key, 'rightarrow')
        disp('Good');
        copyfile([folder '/' filelist(i).name], ...
            [folder '\Good_examples']);
    elseif strcmp(evnt.Key, 'leftarrow')
        disp('Bad');
        copyfile([folder '\' filelist(i).name], ...
            [folder '\Bad_examples']);
    end
end

i = i + 1;

if i <= length(filelist)
    [TS, fs] = audioread([folder '/' filelist(i).name]);

    % Show next file's sonogram
    [sonogram_im,~,~]=zftftb_pretty_sonogram(TS, fs, ...
        'len', 34, 'overlap', 33, 'clipping', [-3 2], 'filtering', 300);

    imshow(flip(sonogram_im, 1));
    colormap hot;
else
    disp('Finished!');
end

end