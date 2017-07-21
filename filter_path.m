function processed = filter_path(raw, threshold)

[~, distance] = find_speed(raw(:,1), raw(:,2), raw(:,3));

% If any distance is > threshold, filter
for j = 1 : 10
    disp('New loop');
    idx = find(distance > threshold);
    %idx
    for i = 1 : length(idx)
        raw(idx(i), 1) = raw(idx(i), 1) + raw(idx(i) + 1, 1);
    end
    raw(idx + 1,:) = [];
    [~, distance] = find_speed(raw(:,1), raw(:,2), raw(:,3));
    %plot(raw(:,2), raw(:,3));
    %waitforbuttonpress;
end

processed = raw;
        
    
    

