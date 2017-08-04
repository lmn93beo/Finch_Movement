function heatmap = find_heat_map(x, y, dt, x_res, y_res)

heatmap = zeros(x_res, y_res);
for i = 1 : (numel(x) - 1)
    x_coord = ceil(x(i));
    y_coord = ceil(y(i));
    %fprintf('coords = %d, %d; i = %d\n', x_coord, y_coord, i);
    heatmap(x_coord, y_coord) = heatmap(x_coord, y_coord) + dt(i);
end