function rmat = alignVectors(avec, bvec)
% Find a rotation matrix such that avec aligns with bvec, i.e:
% rmat*avec(:) is parallel to bvec.

vec_c = cross(avec/norm(avec), bvec/norm(bvec));

if isequal(round(vec_c,10),zeros(size(vec_c)))
%    rmat = diag(bvec/norm(bvec)./avec*norm(avec));
%    rmat(isnan(rmat)) = 1;
   rmat = eye(length(vec_c)) * dot(avec,bvec)/norm(avec)/norm(bvec);
   return
end

ssc = [0 -vec_c(3) vec_c(2); vec_c(3) 0 -vec_c(1); -vec_c(2) vec_c(1) 0];

rmat = eye(3) + ssc + ssc^2*(1-dot(avec/norm(avec), bvec/norm(bvec)))/norm(vec_c)^2;
