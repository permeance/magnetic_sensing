%% Magnetically steerable catheter magnetic localization simulation
% model: ideal dipole model
% sensor configuration: 1. rectangular sensor array
%                       2. circular sensor array
% variables: distance 

% Start with 4x4 arrays in circular sensor plate array
clear;close all;clc;

% Magnetic moment M computation
mu_0 = 4*pi*1e-7;

OD_mag = 3.175e-3;  % outer diameter of PM  [m]
ID_mag = OD_mag/2;  % inner diameter of PM  [m]
length_mag = OD_mag*2;   % length of PM  [m]
V_pm = pi*(OD_mag^2-ID_mag^2^2)/4*length_mag;  % volume of PM
Br = 1.25; % magnetic remanance

M = V_pm*Br/mu_0;


% Whole procedure: set the PM location and orientation in advance, compute the
% analytical magnetic field in all 16 sensors locations in hall effect sensor measuring direction. 
% Use the 16 sensor measurements + manual added noise with 
% different level of magnitude and perform L-M least square optimization
% algorithm to estimate the location and orientation

% Assumption: stationary PM magnet (later with trajectory in space over time and estimate the trajectory)
%             ideal dipole model

% Sensor array parameters
% All coordinates here
L = 0.025;  % sensor interval distance [m]
R = (79.67/2)*1e-3;  % circular sensor array radius [m]


%% 4x4 Circular sensor array confuguration
n_sens = 16;

magnet_distance = 41.39; %mm
dim_repeat = ones(1,3)*magnet_distance; 

%all sensors working
x_s = [zeros(1,8*3),dim_repeat, -dim_repeat,dim_repeat, -dim_repeat,dim_repeat,-dim_repeat,dim_repeat, -dim_repeat]*1e-3; % 6 zeros and alternating x pos and neg
y_s = [repelem(51.4,2*3),repelem(76.4,2*3),repelem(101.4,2*3),repelem(126.4,2*3),repelem(51.4,2*3),repelem(76.4,2*3),repelem(101.4,2*3),repelem(126.4,2*3)]*1e-3; % decreasing from 126.4 to 51.4 and increaseing to 126.4.
z_s = [dim_repeat, -dim_repeat,dim_repeat, -dim_repeat,dim_repeat, -dim_repeat, dim_repeat, -dim_repeat,zeros(1,8*3)]*1e-3; %alternating z pos and neg, and zeros
xyz_s = [x_s;y_s;z_s];  % i-th column is i-th sensor location (x_i,y_i,z_i)

% define measurement direction vector (3 x m)
% i-th column shows the [x,y,z] components of the measurement at i-th
% sensor
%all sensor working
meas_dir_s = [eye(3).*[-1;-1;1],...
              eye(3).*[1;1;-1],...
              eye(3).*[-1;-1;1],...
              eye(3).*[1;1;-1],...
              eye(3).*[-1;-1;1],...
              eye(3).*[1;1;-1],...
              eye(3).*[-1;-1;1],...
              eye(3).*[1;1;-1],...
              fliplr(eye(3)).*[1;-1;1],...
              fliplr(eye(3)).*[-1;-1;-1],...
              fliplr(eye(3)).*[1;-1;1],...
              fliplr(eye(3)).*[-1;-1;-1],...
              fliplr(eye(3)).*[1;-1;1],...
              fliplr(eye(3)).*[-1;-1;-1],...
              fliplr(eye(3)).*[1;-1;1],...
              fliplr(eye(3)).*[-1;-1;-1] ];

% meas_dir_s = meas_dir_s./sqrt(sum(meas_dir_s.^2));  % normalization to unit norm in each direction

% plot sensor configuration 
alpha = 0:0.01:2*pi;
figure
plot3(x_s,y_s,z_s,'rx')
hold on
plot3(R*cos(alpha), 2.0560*L*ones(1,length(alpha)) , R*sin(alpha),'k')
plot3(R*cos(alpha), 3.0560*L*ones(1,length(alpha)) , R*sin(alpha),'k')
plot3(R*cos(alpha), 4.0560*L*ones(1,length(alpha)) , R*sin(alpha),'k')
plot3(R*cos(alpha), 5.0560*L*ones(1,length(alpha)) , R*sin(alpha),'k')
plot3([0 0],[2.0560*L 5.0560*L],[R R],'k')
plot3([-R -R],[2.0560*L 5.0560*L],[0 0],'k')
plot3([0 0],[2.0560*L 5.0560*L],[-R -R],'k')
plot3([R R],[2.0560*L 5.0560*L],[0 0],'k')
title('Sensor configuration')

%% Preset PM dipole location and orientation variable
% (x0,y0,z0)  (sin(theta0)cos(phi0) , sin(theta0)sin(phi0) , cos(theta0))
x0 = -0.0;  % [m]
y0 = 0.089;  % [m]
z0 = 0.0;  % [m]
theta0 = pi/2;  % [rad]
phi0 = pi/2;  % [rad]
% theta0 = pi/2;  % [rad]
% phi0 = pi/2;  % [rad]
xyz_pm = [x0;y0;z0];
pm_all = [x0;y0;z0;theta0;phi0];

% Disturbance field G
G_x = 0;
G_y = 0;
G_z = 0;
G = [G_x;G_y;G_z];

% saturation obtained from actual Hall Effect sensor
sat = 0.1;  % [T]

% Given known PM position and orientation, magnetic moment, sensor array
% configuration, compute the magnetic field at all sensor locations
% B_sx/B_sy/B_sz are 1x16 vector with i-th element being i-th sensor x/y/z field
% compute the actual saclar composite measurement (1 x m) at all sensor
% locations
B_measure_theoretical = PM_forward_field(M,G,pm_all,xyz_s,meas_dir_s,sat);

%% Timeline 0~t_final
% first assume stationary PM s.t. at each moment the forward generated
% field is constant
t_final = 10;  % [s]
dt = 0.1;  % sampling time [s]
t = 0:dt:t_final;  % time history
n_t = length(t);  % length of time data

% Simulate measurement over time
% Here consider circular array s.t. measurement is computed based on its
% direction
% B_meas_ideal rows: time index, columns: i-th sensor
B_meas_ideal = ones(n_t,1)*B_measure_scalar;

% Add noise into measurement on purpose with different level of magnitude
noise_mu = 0;  % mean
noise_sigma = 1e-7;  % variance
noise = noise_mu + noise_sigma*randn(n_t,39);  % generating random noise according to given distribution

% Final corrupted measurement 
B_meas = B_meas_ideal + noise;

% some plots
figure
plot(t,B_meas(:,6))
hold on 
plot([0,t(end)],[B_meas_ideal(1,6) B_meas_ideal(1,6)])
xlabel('Time[s]')
ylabel('Sensor measurement')
legend('corrupted','ideal')

%% Backward estimation phase
% Given measurement of all sensors over a time horizon
% consider at one time, the measurement B_meas is 1 x n_sens vector

% Objective function: f_err = || B_est - B_meas ||^2
% Variable: pm_hat = (x_hat,y_hat,z_hat,theta_hat,phi_hat) as estimation of the position and orientation

% Disturbance field G
G_x = 0;
G_y = 0;
G_z = 0;
G = [G_x;G_y;G_z];

% initial guess on parameter estimation at time 0
pm_hat_0 = [-0.004;0.0892;-0.002;pi/2+0.1;pi/2-0.1];   % (x_hat0,y_hat0,z_hat0,theta_hat0,phi_hat0)

% Compute Analytic Jacobian matrix： J <- R^(m x n) here
J = Analytic_Jacobian_Mag_cir_array(M,pm_hat_0,xyz_s,meas_dir_s);


% Levenberg–Marquardt least square algorithm solving for optimal position/orientation estimation
% test
% B_meas_test = B_measure_scalar';
B_meas = [0.000901282, 0.000436538, 0.045442308, 0.001552564, -0.004180128, 0.042160256, 0.000209615, 0.048811538, 0.036483974...
          0.003489103, 0.038342949, 0.039427564, -0.006405128, 0.043912821, -0.027933974,0.00502244, 0.04273333, 0.03582500, ...
          -0.00012756, 0.03831731, 0.03827115, 0.00448718, 0.04590128, -0.03168333, 0.00303590, -0.00408141, 0.04245192, ...
          0.00123013, 0.00194615, -0.04616603, -0.00324615, -0.00096923, -0.05197692, -0.00185769, 0.04606346, -0.03855192...
          0.00274679, 0.04433654, -0.02420192]*1e-4*10000/3000;
pm_hat_opt = PM_backward_estimation(B_meas',pm_hat_0,M,G,xyz_s,meas_dir_s); 

% weighting among parameters to be added!


%% Timeline estimation
% use the current estimation for next step initial guess
% record the estimation history
% record the requiered computation time
pm_est_history = zeros(n_t,5);
pm_err_history = zeros(n_t,5);
comp_time_history = zeros(n_t,1);
pm_last = pm_hat_0;
for i = 1:n_t
    tic
    B_meas_i = B_meas(i,:)';
    pm_last = PM_backward_estimation(B_meas_i,pm_last,M,G,xyz_s,meas_dir_s); 
    pm_est_history(i,:) = pm_last;
    pm_err_history(i,:) = pm_last - pm_all; 
    comp_time_history(i) = toc;
end

% post data process: compute the standard deviation
mean_out = mean(pm_est_history);
sigma_out = std(pm_est_history);

% noise level ratio
J_1 = sigma_out/noise_sigma;

% position error


% plot the estimation over time
figure()
plot(t,pm_err_history(:,1))
xlabel('Time [s]')
ylabel(' X position [m]')
title('X position estimation error over time')

figure()
plot(t,pm_err_history(:,2))
xlabel('Time [s]')
ylabel(' Y position [m]')
title('Y position estimation error over time')

figure()
plot(t,pm_err_history(:,3))
xlabel('Time [s]')
ylabel(' Z position [m]')
title('Z position estimation error over time')

figure()
plot(t,pm_err_history(:,4))
xlabel('Time [s]')
ylabel(' Theta orientation [rad]')
title('Theta orientation estimation error over time')

figure()
plot(t,pm_err_history(:,5))
xlabel('Time [s]')
ylabel(' Phi orientation [rad]')
title('Phi orientation estimation error over time')


figure
plot(t,comp_time_history)
xlabel('Time [s]')
ylabel('Computation time [s]')







