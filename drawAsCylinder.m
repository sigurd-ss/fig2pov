function drawAsCylinder(fid, pp)


if isequal(pp.Type ,'surface')
    vertices = unique([pp.XData(:) pp.YData(:) pp.ZData(:)], 'rows', 'stable');
elseif isequal(pp.Type ,'patch')
    all_verts = pp.Faces(:);
    all_verts(isnan(all_verts)) = [];
    vertices = pp.Vertices(all_verts,:);
end

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

[rot_curve, centr_axis, center] = fit_cylinder(vertices);
Npts = size(rot_curve,1);
if Npts >=3
    pfit = polyfit(rot_curve(:,1), rot_curve(:,2), 2);
else
    pfit = polyfit(rot_curve(:,1), rot_curve(:,2), 1);
    pfit = [0 pfit(:)'];
end

% Write povray code to generate the rotation object (cylinder, cone or lathe)
if norm(pfit(1:2))/norm(pfit(3)) < 1e-5    % constant -> cylinder
    fprintf(fid,'cylinder {\n');
    fprintf(fid,'\t<%10.6f, %10.6f, %10.6f>,\n', 0, rot_curve(1, 1), 0);
    fprintf(fid,'\t<%10.6f, %10.6f, %10.6f>,\n', 0, rot_curve(end, 1), 0);
    fprintf(fid,'\t%10.6f\n', mean(rot_curve(:,2)));
    fprintf(fid,'\topen\n');  % TODO: determine whether open or closed
elseif norm(pfit(1))/norm(pfit(2:3)) < 1e-5 % linear -> cone
    fprintf(fid,'cone {\n');
    fprintf(fid,'\t<%10.6f, %10.6f, %10.6f>, %10.6f\n', 0, rot_curve(1, 1), 0, rot_curve(1, 2));
    fprintf(fid,'\t<%10.6f, %10.6f, %10.6f>, %10.6f\n', 0, rot_curve(end, 1), 0, rot_curve(end, 2));
    fprintf(fid,'\topen\n');  % TODO: determine whether open or closed
else    % quadratic or more -> lathe
    fprintf(fid,'lathe {\n');
    fprintf(fid,'\tlinear_spline\n');
    fprintf(fid,'\t%d,\n', Npts);
    for i_r=1:Npts
        fprintf(fid,'\t<%10.6f, %10.6f>', rot_curve(i_r, 2), rot_curve(i_r, 1));
        if i_r ~= Npts
            fprintf(fid,',');
        end
        fprintf(fid,'\n');
    end
end
face_color = pp.FaceColor;
fprintf(fid,'\tpigment { color rgbt <%4.3f, %4.3f, %4.3f, %4.3f> }\n',face_color(1), face_color(2), face_color(3), 0);
% TODO: add rotation/translation if needed
rmat = alignVectors(centr_axis([1 3 2]), [0 1 0]);
fprintf(fid,'\t\tmatrix <%10.6f, %10.6f, %10.6f,\n', rmat(1,1), rmat(1,2), rmat(1,3));
fprintf(fid,'\t\t\t%10.6f, %10.6f, %10.6f,\n', rmat(2,1), rmat(2,2), rmat(2,3));
fprintf(fid,'\t\t\t%10.6f, %10.6f, %10.6f,\n', rmat(3,1), rmat(3,2), rmat(3,3));
% fprintf(fid,'\t\tmatrix <%10.6f, %10.6f, %10.6f,\n', rmat(1,1), rmat(1,3), rmat(1,2));
% fprintf(fid,'\t\t\t%10.6f, %10.6f, %10.6f,\n', rmat(2,1), rmat(2,3), rmat(2,2));
% fprintf(fid,'\t\t\t%10.6f, %10.6f, %10.6f,\n', rmat(3,1), rmat(3,3), rmat(3,2));
fprintf(fid,'\t\t\t%10.6f, %10.6f, %10.6f>\n', center(1), center(3), center(2));

if isfield(povray_options, 'Texture')
    fprintf(fid,'\ttexture { %s }\n', povray_options.Texture);
end
if isfield(povray_options, 'InteriorTexture')
    fprintf(fid,'\tinterior_texture  { %s }\n', povray_options.InteriorTexture);
end
fprintf(fid,'}\n');

