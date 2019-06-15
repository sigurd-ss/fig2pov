function drawAsSphere(fid, pp)
% drawAsSphere(fid, pp)
%
% Approximate a patch or surface object as a sphere. Determine the relevant
% parameters (center and radius) and write the resulting shape to file using the Povray scripting language. 
%
% Input:
%   - fid: File identifier
%   - pp: graphics object (path or surface)
%
% Author: Sigurd Schelstraete, 2019

% Fit sphere to the data
if isequal(pp.Type ,'surface')
    vertices = [pp.XData(:) pp.ZData(:) pp.YData(:)];
elseif isequal(pp.Type ,'patch')
    all_verts = pp.Faces(:);
    all_verts(isnan(all_verts)) = [];
    vertices = pp.Vertices(all_verts,:);
else
    error('Object type not supported')
end

if isequal(pp.Parent.Type, 'hgtransform')
    ht = pp.Parent;
    vertices = vertices*ht.Matrix(1:3,:)';
end
[x0, y0, z0, r] = fit_sphere(vertices);

% Write povray code to generate the sphere
if isfield(pp.('UserData'),'povray')
    povray_options = pp.('UserData').('povray');
else
    povray_options = struct();
end

if isequal(pp.FaceColor, 'flat') || isequal(pp.FaceColor, 'interp')
    facecolor = NaN;
else
    facecolor = pp.FaceColor;
end

fprintf(fid,'sphere {\n');
fprintf(fid,'\t<%10.6f, %10.6f, %10.6f>, %10.6f\n', x0, y0, z0, r);
if ~any(isnan(facecolor))
    fprintf(fid,'\tpigment{rgb <%10.6f, %10.6f, %10.6f>}\n', ...
        pp.FaceColor(1), pp.FaceColor(2), pp.FaceColor(3));
end
if isfield(povray_options, 'Texture')
    fprintf(fid,'\ttexture { %s }\n', povray_options.Texture);
end
if isfield(povray_options, 'InteriorTexture')
    fprintf(fid,'\tinterior_texture  { %s }\n', povray_options.InteriorTexture);
end
fprintf(fid,'}\n\n');
