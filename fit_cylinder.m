function [rot_curve, rot_axis, center] = fit_cylinder(data)
%
%
% Input:
%   data: Nx3 matrix of N (3D) data points

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
%     temp = data - data*P(:,i_eig)*P(:,i_eig)' - repmat(center, Npts,1);
    temp = data_centered - data_centered*P(:,i_eig)*P(:,i_eig)';
    temp = [data_centered*P(:,i_eig) sqrt(sum(abs(temp).^2,2))];
    temp = unique(round(temp,5),'rows');
    if size(temp,1) < min_n_vals
        min_n_vals = size(temp,1);
        rot_curve = temp;
        rot_axis = P(:,i_eig);
    end
end
