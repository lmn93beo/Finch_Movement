folder = 'LB21withwhite';
files = dir([folder '/*.csv']);

raw = csvread([folder '/' files(2).name]);

% Discard rows with (0,0)
raw(raw(:,2) == 0 & raw(:,3) == 0,:) = [];
raw(raw(:,2) < 10,:) = [];

x = raw(:,2);
y = raw(:,3);

% Perform smoothing
x = movmean(x, 15);
y = movmean(y, 15);



% Plot trajectory
figure(1);
subplot(1,2,1);
plot(x, y);
axis ij;
title('Trajectory');
subplot(1,2,2);
scatter(x, y);
axis ij;
title('Positions');

% Find the speed between two points
start_pt = raw(1:end-1, 2:3);
end_pt = raw(2:end, 2:3);
ds_squared = (start_pt - end_pt) .^ 2;
distance = sqrt(sum(ds_squared, 2));

t1 = raw(1:end-1, 1);
t2 = raw(2:end, 1);
dt = t2 - t1;
speed = distance ./ t1;

figure(2);
plot(speed);
title('Speed of the animal');
xlabel('Time (secs)')
ylabel('Speed (pix/sec)')

% Find number of crossings
boundary = 70;
crossings = (start_pt(:,1) > boundary & end_pt(:,1) < boundary) | ...
            (start_pt(:,1) < boundary & end_pt(:,1) > boundary);
possible_jump = find(crossings);
jumps = x(possible_jump - 4) < 40 & x(possible_jump + 4) > 100 | ...
    x(possible_jump + 4) < 40 & x(possible_jump - 4) > 100;

fprintf('Number of crossings = %d\n', sum(jumps));

% Heat map
heatmap = zeros(150, 120);
for i = 1 : (numel(x) - 1)
    x_coord = ceil(x(i));
    y_coord = ceil(y(i));
    heatmap(x_coord, y_coord) = heatmap(x_coord, y_coord) + (t2(i));
end
figure(3);
imshow(heatmap' / 2);
colormap jet;
title('Heat map');
axis ij;


