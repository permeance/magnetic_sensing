close all
clear

%reading the file named
data = xlsread('no_magnet_sensing');
% data = xlsread('centered_magnet_sensing');

%naming the raw data from excel sheet
%Data on excel is labeled as X1,X2, etc. 
time_stamp = data(:,1);
X1_raw = data(:,2);
Y1_raw = data(:,3);
Z1_raw = data(:,4);
X2_raw = data(:,5);
Y2_raw = data(:,6);
Z2_raw = data(:,7);
sensor_raw = data(:,8);

num_sensors = unique(sensor_raw); %count numbe of sensors

%sensors 0-3 are on top and bottom
%sensors 4-7 are left and right
% vertical_sensors = num_sensors(1:half);
% horizontal_sensors = num_sensors(half + 1 : end);
sensor_tables = cell2table(cell(1, length(num_sensors))); %presetting tables for each sensor

% sensor_list = {sensor_0, sensor_1, sensor_2, sensor_3, sensor_4, sensor_5, sensor_6, sensor_7};

%Loop to find data from each sensor 0-7
for sensor_step = 1:length(num_sensors)
    i=1;
    for list_item = 1:length(time_stamp)
        if sensor_step == (sensor_raw(list_item)+1) %save data per sensor  
            X_top(i,sensor_step) = X1_raw(list_item);
            Y_top(i,sensor_step) = Y1_raw(list_item);
            Z_top(i,sensor_step) = Z1_raw(list_item);
            time(i,sensor_step) = time_stamp(list_item);


            X_bottom(i,sensor_step) = X2_raw(list_item);
            Y_bottom(i,sensor_step) = Y2_raw(list_item);
            Z_bottom(i,sensor_step) = Z2_raw(list_item);
            i = i+1;
        end
    end
    
    top_sensor_table = table(time(:,sensor_step),X_top(:,sensor_step),Y_top(:,sensor_step),Z_top(:,sensor_step),'VariableNames', {'Time','X','Y','Z'});
    top_sensor_table(top_sensor_table.X == 0, :) = [];
    bottom_sensor_table = table(time(:,sensor_step), X_bottom(:,sensor_step),Y_bottom(:,sensor_step),Z_bottom(:,sensor_step), 'VariableNames', {'Time','X','Y','Z'});
    bottom_sensor_table(bottom_sensor_table.X == 0, :) = [];

    sensor_list{sensor_step} = table({top_sensor_table}, {bottom_sensor_table}, 'VariableNames', {'TopSensor', 'BottomSensor'});
end

%Naming each sensor to derived table
sensor0_top = sensor_list{1,1}.TopSensor{1,1};
sensor1_top = sensor_list{1,2}.TopSensor{1,1};
sensor2_top = sensor_list{1,3}.TopSensor{1,1};
sensor3_top = sensor_list{1,4}.TopSensor{1,1};
sensor4_right = sensor_list{1,5}.TopSensor{1,1};
sensor5_right = sensor_list{1,6}.TopSensor{1,1};
sensor6_right = sensor_list{1,7}.TopSensor{1,1};
sensor7_right = sensor_list{1,8}.TopSensor{1,1};

sensor0_bottom = sensor_list{1,1}.BottomSensor{1,1};
sensor1_bottom = sensor_list{1,2}.BottomSensor{1,1};
sensor2_bottom = sensor_list{1,3}.BottomSensor{1,1};
sensor3_bottom = sensor_list{1,4}.BottomSensor{1,1};
sensor4_left = sensor_list{1,5}.BottomSensor{1,1};
sensor5_left = sensor_list{1,6}.BottomSensor{1,1};
sensor6_left = sensor_list{1,7}.BottomSensor{1,1};
sensor7_left = sensor_list{1,8}.BottomSensor{1,1};

sensor_list = {sensor0_top, sensor0_bottom, sensor1_top, sensor1_bottom,...
    sensor2_top, sensor2_bottom,sensor3_top, sensor3_bottom,sensor4_right,...
    sensor4_left,sensor5_right, sensor5_left,sensor6_right, sensor6_left,...
    sensor7_right, sensor7_left};

sensor_names = ["Sensor 0 Top", "Sensor 0 bottom", "Sensor1 top", "Sensor1 bottom",...
                "Sensor 2 top", "Sensor 2 bottom","Sensor 3 top", "Sensor 3 bottom","Sensor 4 right",...
                "Sensor 4 left","Sensor 5 right", "Sensor 5 left","Sensor 6 right", "Sensor 6 left",...
                "Sensor 7 right", "Sensor 7 left"]; 

            

for i = 1:length(sensor_list)
    current_table = sensor_list{i};
    XYZ_means = mean(current_table{:,["X", "Y","Z"]});
    XYZ_std = std(current_table{:,["X", "Y","Z"]});
    sensor_XYZ_avg(i,:) = XYZ_means;
    sensor_XYZ_std(i,:) = XYZ_std;
end
avg_MagField = table(sensor_names(:),sensor_XYZ_avg(:,1), sensor_XYZ_avg(:,2),sensor_XYZ_avg(:,3), 'VariableNames', {'Sensor','X_avg','Y_avg','Z_avg'});
StD_MagField = table(sensor_names(:),sensor_XYZ_std(:,1), sensor_XYZ_std(:,2),sensor_XYZ_std(:,3), 'VariableNames', {'Sensor','X_StD','Y_StD','Z_StD'});
writetable(avg_MagField, "EarthMagneticField.xlsx");


for i = 1:length(sensor_list)
    current_table = sensor_list{i};
    figure(i)
    time_step = current_table.Time;
    X_graph = current_table.X;
    Y_graph = current_table.Y;
    Z_graph = current_table.Z;

    plot(time_step,X_graph); hold on
    plot(time_step,Y_graph)
    plot(time_step,Z_graph)
    title(sensor_names(i))
    legend('X','Y','Z')
    
end 
close all
