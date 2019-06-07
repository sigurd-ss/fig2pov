function [x0, y0, z0, r] = fit_sphere(data)
% Fit a set of data points to a sphere
% 
% See e.g. https://jekel.me/2015/Least-Squares-Sphere-Fit/ for a
% description of the algorithm
%
% Input:
%   data: Nx3 matrix of N (3D) data points

[Npts, dim] = size(data);
if dim ~=3
    error('data points should be three-dimensional')
end

ff = sum(data.^2, 2);

Amat = [2*data ones(Npts,1)];

ctemp = pinv(Amat)*ff;

x0 = ctemp(1);
y0 = ctemp(2);
z0 = ctemp(3);
r = sqrt(ctemp(4) + x0^2 + y0^2 + z0^2);





