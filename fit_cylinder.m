function [rot_curve, rot_axis, center] = fit_cylinder(data)
% [rot_curve, rot_axis, center] = fit_cylinder(data)
%
% Fit a set of data points to a cylinder. It is assumed that all points are
% on an object that is formed by rotating a curve around an axis of
% symmetry. In that case, the fucntion will recover the curve and the axis.
% If this is not the case, results can be unpredictable. This is not a
% general-purpose function for finding approximate cylinders that best
% match a set of data points.
%
% Input:
%   - data: Nx3 matrix of N (3D) data points
%
% Output:
%   - rot_curve: 2D curve 
%   - rot_axis: axis of symmetry
%   - center: mean of the input data
%
% Author: Sigurd Schelstraete, 2019

[Npts, dim] = size(data);
if dim ~=3
    error('data points should be three-dimensional')
end

center = mean(data,1);
data_centered = data - repmat(center, Npts,1);

Rmat = data_centered'*data_centered;    % 3x3 matrix
[P,~] = eig(Rmat, 'vector');
P = real(P);

min_n_vals = Inf;
for i_eig=1:3
    temp = data_centered - data_centered*P(:,i_eig)*P(:,i_eig)';
    temp = [data_centered*P(:,i_eig) sqrt(sum(abs(temp).^2,2))];
    temp = unique(round(temp,5),'rows');
    if size(temp,1) < min_n_vals
        min_n_vals = size(temp,1);
        rot_curve = temp;
        rot_axis = P(:,i_eig);
    end
end
