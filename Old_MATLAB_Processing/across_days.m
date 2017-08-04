%% Animal info
animal_info = struct('name', {'LB06', 'LB06','LB06', 'LB06'},...
                     'starting', {datenum(2016, 7, 18, 0, 0, 0),...
                                  datenum(2016, 7, 20, 0, 0, 0),...
                                  datenum(2016, 7, 18, 0, 0, 0),...
                                  datenum(2016, 7, 20, 0, 0, 0)},...
                     'ending',   {datenum(2016, 7, 18, 21, 0, 0),...
                                  datenum(2016, 7, 20, 21, 0, 0),...
                                  datenum(2016, 7, 18, 21, 0, 0),...
                                  datenum(2016, 7, 20, 21, 0, 0)},...
                     'coef', {1,1,1,1});

%% Process
for i = 1:length(animal_info)
    raw = xlsread('movement_profiles.xlsx', animal_info(i).name);

    timestamps = datenum(raw(:,1:6));
    speed = raw(:,7);
    jumps = raw(:,8);

    starting = animal_info(i).starting;
    ending = animal_info(i).ending;
    
    times = timestamps(timestamps > starting & timestamps < ending);
    speed = speed(timestamps > starting & timestamps < ending);
    jumps = jumps(timestamps > starting & timestamps < ending);
    
    plot(cumsum(speed * animal_info(i).coef));
    hold on;

end

legend({animal_info.name});
datetick('x', 'HHPM');

