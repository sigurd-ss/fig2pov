function rmat = alignVectors(avec, bvec)
% rmat = alignVectors(avec, bvec)
% 
% Find a rotation matrix such that the vector 'avec' aligns with the vector
% 'bvec', i.e: rmat*avec(:) is parallel to bvec. 
%
% Input:
%   - avec: vector (3x1 or 1x3)
%   - bvec: vector (3x1 or 1x3)
% 
% Output:
%   - rmat: rotation matrix such that rmat*avec(:) is parallel to bvec(:)
%
% Author: Sigurd Schelstraete, 2019

vec_c = cross(avec/norm(avec), bvec/norm(bvec));

if isequal(round(vec_c,10),zeros(size(vec_c)))
   rmat = eye(length(vec_c)) * dot(avec,bvec)/norm(avec)/norm(bvec);
   return
end

ssc = [0 -vec_c(3) vec_c(2); vec_c(3) 0 -vec_c(1); -vec_c(2) vec_c(1) 0];

rmat = eye(3) + ssc + ssc^2*(1-dot(avec/norm(avec), bvec/norm(bvec)))/norm(vec_c)^2;
