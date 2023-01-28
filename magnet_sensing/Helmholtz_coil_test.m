%% This script is characterizing the magnetic field generated by the Helmholtz coils

%% test the numerical integration for magnetic field calculation
% accuracy and computation time
clear;close all; clc;

mu_0 = 4*pi*1e-7;
x_p = 0;
y_p = 0;
z_p = 1e-3;
R = 20*1e-3;

% use intergral
fun = @(theta,x,y,z,R) z*R*cos(theta)./(x^2+y^2+z^2+R^2-2*x*R.*cos(theta)-2*x*R.*sin(theta)).^(3/2);
Bx = integral(@(x) fun(x,x_p,y_p,z_p,R),0,2*pi);



% use trapz
theta = 0:0.00001:2*pi; % specify the intervals
dBx = z_p*R.*cos(theta)./(x_p^2+y_p^2+z_p^2+R^2-2*x_p*R.*cos(theta)-2*y_p*R.*sin(theta)).^(3/2);
Bx_2 = trapz(theta,dBx);


% integral more accurate









