function [speed, distance] = find_speed(x, y, dt)

points = [x y];
start_pt = points(1:end-1, :);
end_pt = points(2:end, :);
ds_squared = (start_pt - end_pt) .^ 2;
distance = sqrt(sum(ds_squared, 2));

speed = sum(distance) / sum(dt);