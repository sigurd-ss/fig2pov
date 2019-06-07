function fig2pov(hax, pov_filename)
% Convert axes object to povray script that regenerates the content of the
% axes in Povray. Additional Povray options (such as texture, ...)can be 
% specificed in the UserData field of various objects.
%
% Input
%   - hax: handle of axes object
%   - pov_filename to write povray script to

if nargin < 2
    pov_filename = 'fig.pov';
end

if nargin < 1
	hax = gca;
end

% Open file for writing
fid = fopen(pov_filename,'w');

% Identify graphics objects contained in the specified axes 
patch_obj = findobj(hax, 'Type', 'patch');   % all objects of type 'patch'
surf_obj = findobj(hax, 'Type', 'surface');   % all objects of type 'surface'
line_obj = findobj(hax, 'Type', 'line');   % all objects of type 'line'

% Determine light properties if specified by axes, otherwise set default
% light position equal to camera position
light_obj = findobj(hax, 'Type', 'Light');
if isempty(light_obj)
    light_obj = struct('Position', campos, 'Color', [1 1 1], 'UserData', []);
end

% Get povray options specified for axes object, if any
if isfield(hax.UserData,'povray')
    axes_povray_options = hax.UserData.povray;
else
    axes_povray_options = struct();
end

% General Povray information and frequently used include files
fprintf(fid,'#version 3.7;\nglobal_settings { assumed_gamma 1 }\n\n');
fprintf(fid,'#include "colors.inc"\n');
fprintf(fid,'#include "woods.inc"\n');
fprintf(fid,'#include "stones.inc"\n');
fprintf(fid,'#include "metals.inc"\n');
fprintf(fid,'#include "textures.inc"\n');
fprintf(fid,'#include "finish.inc"\n\n');

% Declarations, if any are present in the povray options specified for axes object
if isfield(axes_povray_options, 'Define')
    defnames = fieldnames(axes_povray_options.Define);
    for i_def=1:numel(defnames)
        defstr = split(axes_povray_options.Define.(defnames{i_def}), newline);
        fprintf(fid,'#declare %s = \n', defnames{i_def});
        for i_p=1:numel(defstr)
            fprintf(fid,'%s\n', defstr{i_p});
        end
        fprintf(fid,'\n\n');
    end
end

% Camera properties
cam_angle = hax.CameraViewAngle*1.05;   % 5% extra margin
if dot(campos-camtarget, [1 1 0]) <= eps    % special handling needed for 2D view
    camoffset = 1e-4;
else
    camoffset = 0;
end
fprintf(fid,'camera {\n');
fprintf(fid,'\tlocation <%.4f, %.4f, %.4f>\n', hax.CameraPosition(1) + camoffset, hax.CameraPosition(3), hax.CameraPosition(2));
fprintf(fid, '\tup     y\n');
fprintf(fid, '\tright     x*image_width/image_height\n');
fprintf(fid, '\tangle degrees(2*atan2(image_width/image_height * tan(%.4f), 1))\n', deg2rad(cam_angle/2));
fprintf(fid, '\tlook_at <%.4f, %.4f, %.4f>\n', hax.CameraTarget(1), hax.CameraTarget(3), hax.CameraTarget(2));
fprintf(fid,'}\n\n');

% Light properties
for kk=1:numel(light_obj)
    if isfield(light_obj(kk).UserData,'povray')
        povray_options = light_obj(kk).UserData.povray;
    else
        povray_options = struct();
    end
    
    if isfield(povray_options,'ShadowLess') && ~povray_options.ShadowLess
        shadow_txt = '';
    else
        shadow_txt = 'shadowless';
    end
    
    fprintf(fid,'light_source {\n\t<%.2f, %.2f, %.2f>\n\tcolor rgb<%.2f, %.2f, %.2f>\n',...
        light_obj(kk).Position(1), light_obj(kk).Position(3), light_obj(kk).Position(2), ...
        light_obj(kk).Color(1), light_obj(kk).Color(2), light_obj(kk).Color(3) ...
        );
    if ~isempty(shadow_txt)
        fprintf(fid, '\t%s\n', shadow_txt);
    end
    fprintf(fid,'}\n\n');
end

% Background and Plane
if isfield(axes_povray_options,'Plane')
    fprintf(fid,'plane {\n\t<%.2f, %.2f, %.2f>, %.2f \n', ...
        axes_povray_options.Plane(1), axes_povray_options.Plane(3), axes_povray_options.Plane(2), axes_povray_options.Plane(4));
    if isfield(axes_povray_options,'PlaneColor')
        if isnumeric(axes_povray_options.PlaneColor) && numel(axes_povray_options.PlaneColor)==3
            fprintf(fid, '\tpigment {color rgb<%.2f, %.2f, %.2f>}\n', ...
                axes_povray_options.PlaneColor(1), axes_povray_options.PlaneColor(2), axes_povray_options.PlaneColor(3));
        else
            fprintf(fid, '\tpigment {%s}\n', axes_povray_options.PlaneColor);
        end
    end
    if isfield(axes_povray_options,'PlaneTexture')
        fprintf(fid, '\ttexture { %s }\n', ...
            axes_povray_options.PlaneTexture);
    end
    
    fprintf(fid,'}\n\n');
else
    fprintf(fid,'background { color rgb<%.4f, %.4f, %.4f> }\n\n', ...
        hax.Color(1), hax.Color(2), hax.Color(3));
end

scene_width = 2 * norm(campos) * tan(deg2rad(cam_angle/2));
line_basewidth = scene_width/500;

% Loop over patch object(s)
for i_p = 1:numel(patch_obj)
    pp = patch_obj(i_p);
    if isfield(pp.('UserData'),'povray')
        povray_options = pp.('UserData').('povray');
    else
        povray_options = struct();
    end

    if isfield(povray_options,'drawAsSphere') && povray_options.drawAsSphere
        drawAsSphere(fid, pp)
        continue
    end
    
    if isfield(povray_options,'drawAsCylinder') && povray_options.drawAsCylinder
        drawAsCylinder(fid, pp)
        continue
    end

    [num_faces, ~] = size(pp.Faces);
    fprintf(fid,'#declare faces_%d =\nunion {\n',i_p);
    for i_f=1:num_faces
        Nverts = sum(~isnan(pp.Faces(i_f,:)));
        face_verts = pp.Vertices(pp.Faces(i_f, 1:Nverts), :);
        if size(face_verts, 2) == 2
            face_verts = [face_verts(:,1) zeros(Nverts,1) face_verts(:,2)];
        else
            face_verts = face_verts(:,[1 3 2]);
        end
        face_center = mean(face_verts,1);
        face_normal = cross(face_verts(2,:) - face_verts(1,:), face_verts(3,:) - face_verts(1,:));
        rmat = alignVectors(face_normal, [0 0 1]);
        face_verts = (face_verts - ones(Nverts, 1) * face_center) * rmat';  % should lie in XY plane
        face_verts(:, 3) = 0;    % correct for possible rounding
        fprintf(fid,'\tpolygon {\n');
        fprintf(fid,'\t\t%d,\n', Nverts);
        for i_v=1:Nverts
            fprintf(fid,'\t\t<%10.6f, %10.6f, %10.6f>\n', face_verts(i_v, 1), face_verts(i_v, 2), face_verts(i_v, 3));
        end
        if isequal(patch_obj(i_p).CDataMapping, 'direct')
            face_color = patch_obj(i_p).FaceVertexCData(i_f);
            fprintf(fid,'\t\tpigment { color rgbt <%4.3f, %4.3f, %4.3f, %4.3f> }\n',face_color(1), face_color(2), face_color(3), 0);
        end
        
        fprintf(fid,'\t\tmatrix <%10.6f, %10.6f, %10.6f,\n', rmat(1,1), rmat(1,2), rmat(1,3));
        fprintf(fid,'\t\t\t%10.6f, %10.6f, %10.6f,\n', rmat(2,1), rmat(2,2), rmat(2,3));
        fprintf(fid,'\t\t\t%10.6f, %10.6f, %10.6f,\n', rmat(3,1), rmat(3,2), rmat(3,3));
        fprintf(fid,'\t\t\t%10.6f, %10.6f, %10.6f>\n', face_center(1), face_center(2), face_center(3));
        
        fprintf(fid,'\t}\n');
    end
    fprintf(fid,'}\n\n');
    
    % Add common color, texture, ... for all faces previously defined
    fprintf(fid,'object {\n \tfaces_%d\n',i_p);
    if ~isequal(pp.CDataMapping, 'direct')
        if isfield(povray_options, 'FaceColor')
            obj_color = povray_options.FaceColor;
        else
            obj_color = pp.FaceColor;
        end
        if isfield(povray_options, 'FaceAlpha')
            obj_alpha = povray_options.FaceAlpha;
        else
            obj_alpha = pp.FaceAlpha;
        end
        fprintf(fid,'\tpigment { color rgbt <%4.3f, %4.3f, %4.3f, %4.3f> }\n',obj_color(1), obj_color(2), obj_color(3), 1-obj_alpha);
    end
    fprintf(fid,'\tfinish { ambient %.2f  diffuse %.2f specular %.2f}\n', pp.AmbientStrength, pp.DiffuseStrength, pp.SpecularStrength);
    if isfield(povray_options, 'Texture')
        fprintf(fid,'\ttexture { %s ', povray_options.Texture);
        if isfield(povray_options, 'TextureScale')
            fprintf(fid,'\n\tscale %d ', povray_options.TextureScale);
        end
        fprintf(fid,'}\n');
    end
    if isfield(povray_options, 'InteriorTexture')
        fprintf(fid,'\tinterior_texture { %s ', povray_options.InteriorTexture);
        if isfield(povray_options, 'TextureScale')
            fprintf(fid,'\n\tscale %d ', povray_options.TextureScale);
        end
        fprintf(fid,'}\n');
    end
    
    
    if isequal(pp.Parent.Type, 'hgtransform')
        ht = pp.Parent;
        fprintf(fid,'\tmatrix <%10.6f, %10.6f, %10.6f,\n', ht.Matrix(1,1), ht.Matrix(1,3), ht.Matrix(1,2));
        fprintf(fid,'\t\t%10.6f, %10.6f, %10.6f,\n', ht.Matrix(3,1), ht.Matrix(3,3), ht.Matrix(3,2));
        fprintf(fid,'\t\t%10.6f, %10.6f, %10.6f,\n', ht.Matrix(2,1), ht.Matrix(2,3), ht.Matrix(2,2));
        fprintf(fid,'\t\t%10.6f, %10.6f, %10.6f>\n', ht.Matrix(1,4), ht.Matrix(3,4), ht.Matrix(2,4));
    end   
    
    fprintf(fid,'}\n\n');
    
    % Add edges if configured
    if  isfield(povray_options, 'drawEdges') && povray_options.drawEdges
        edge_radius = pp.LineWidth * line_basewidth;
        if isfield(povray_options, 'EdgeColor')
            edge_col = povray_options.('EdgeColor');
        else
            edge_col = pp.EdgeColor;
        end
        
        pp_edges = polyhedron_edges(pp);
        fprintf(fid,'#declare edges_%d =\nunion {\n',i_p);
        for i_e=1:size(pp_edges.Edges,1)
            base_pt = pp_edges.Vertices(pp_edges.Edges(i_e,1),[1 3 2]);
            cap_pt = pp_edges.Vertices(pp_edges.Edges(i_e,2),[1 3 2]);
            fprintf(fid,'\tcylinder { <%10.6f, %10.6f, %10.6f>, <%10.6f, %10.6f, %10.6f>, %10.6f }\n', ...
                base_pt(1), base_pt(2), base_pt(3), cap_pt(1), cap_pt(2), cap_pt(3), edge_radius);
        end
        unique_inds = unique(pp_edges.Edges(:));
        for i_u=1:length(unique_inds)
            vertex_pt = pp_edges.Vertices(i_u,[1 3 2]);
            fprintf(fid,'\tsphere { <%10.6f, %10.6f, %10.6f>, %10.6f }\n', ...
                vertex_pt(1), vertex_pt(2), vertex_pt(3), edge_radius);
        end
        fprintf(fid,'}\n\n');
        
        fprintf(fid,'object {\n \tedges_%d\n',i_p);
        if isnumeric(edge_col) && numel(edge_col)==3
            fprintf(fid,'\tpigment { color rgb<%.2f, %.2f, %.2f> }\n', ...
                edge_col(1), edge_col(2), edge_col(3));
        else
            fprintf(fid,'\tpigment { %s }\n', edge_col);
        end
        if isfield(povray_options, 'EdgeTexture')
            fprintf(fid,'\ttexture { %s }\n', povray_options.LineTexture);
        end
        fprintf(fid,'}\n\n');
    end
    
    % Add vertices to the faces if vertex properties are specified in the povray options
    if ~isequal(pp.Marker, 'none') && ~(isequal(pp.MarkerFaceColor, 'none') ...
            && isequal(pp.MarkerEdgeColor, 'none'))

        vert_radius = pp.MarkerSize  * line_basewidth;
        
        if isfield(povray_options, 'MarkerFaceColor')
            vert_col = povray_options.('MarkerFaceColor');
        elseif isequal(pp.MarkerEdgeColor, 'auto')
            vert_col = pp.EdgeColor;
        else
            vert_col = pp.MarkerFaceColor;
        end
        
        verts = get(pp, 'Vertices');
        fprintf(fid,'#declare vertices_%d =\nunion {\n',i_p);
        for i_v = 1:size(verts,1)
            fprintf(fid,'\t\tsphere { <%10.6f, %10.6f, %10.6f>, %10.6f }\n', ...
                verts(i_v, 1), verts(i_v, 3), verts(i_v, 2), vert_radius);
        end
        fprintf(fid,'}\n\n');
        
        fprintf(fid,'object {\n \tvertices_%d\n',i_p);
        if isnumeric(vert_col) && numel(vert_col)==3
            fprintf(fid,'\tpigment { color rgb<%.2f, %.2f, %.2f> }\n', ...
                vert_col(1), vert_col(2), vert_col(3));
        else
            fprintf(fid,'\tpigment { %s }\n', vert_col);
        end
        if isfield(povray_options, 'MarkerTexture')
            fprintf(fid,'\ttexture { %s }\n', povray_options.MarkerTexture);
        end        
        fprintf(fid,'}\n\n');
    end
end

% Loop over Surface objects
for i_p = 1:numel(surf_obj)
    pp = surf_obj(i_p);
    if isfield(pp.('UserData'),'povray')
        povray_options = pp.('UserData').('povray');
    else
        povray_options = struct();
    end
    
    if isfield(povray_options,'drawAsSphere') && povray_options.drawAsSphere
        drawAsSphere(fid, pp);
        continue
    end
    
    if isfield(povray_options,'drawAsCylinder') && povray_options.drawAsCylinder
        drawAsCylinder(fid, pp);
        continue
    end

    if isequal(pp.FaceColor, 'flat') || isequal(pp.FaceColor, 'interp')
        facecolor = NaN;
    else
        facecolor = pp.FaceColor;
    end
    
    hh = surf2patch(pp, 'triangles');
    hh = struct('Vertices', hh.vertices, 'Faces', hh.faces);
    N_verts = size(hh.Vertices,1);
    N_faces = size(hh.Faces, 1);

    fprintf(fid,'mesh2 {\n');
    fprintf(fid,'\tvertex_vectors {\n');
    fprintf(fid,'\t\t%d,\n',N_verts);
    for i_v=1:N_verts
        fprintf(fid,'\t\t<%10.6f, %10.6f, %10.6f>', ...
            pp.XData(i_v), pp.ZData(i_v), pp.YData(i_v));
        if i_v ~= N_verts
            fprintf(fid,',\n');
        else
            fprintf(fid,'\n');
        end
    end
    fprintf(fid,'\t}\n\n');
    
    if isfield(povray_options, 'SmoothingOn') && povray_options.SmoothingOn
        [nx, ny, nz] = surfnorm(pp.XData, pp.YData, pp.ZData);
        fprintf(fid,'\tnormal_vectors {\n');
        fprintf(fid,'\t\t%d,\n',N_verts);
        
        for i_v=1:N_verts
            fprintf(fid,'\t\t<%10.6f, %10.6f, %10.6f>', ...
                nx(i_v), nz(i_v), ny(i_v));
            if i_v ~= N_verts
                fprintf(fid,',\n');
            else
                fprintf(fid,'\n');
            end
        end
        fprintf(fid,'\t}\n\n');
    end
    
    if isequal(pp.FaceColor, 'flat') || isequal(pp.FaceColor, 'interp')
        colmap = colormap;
        col_range = [min(pp.CData(:)) max(pp.CData(:))];
        fprintf(fid,'\ttexture_list {\n');
        fprintf(fid, '\t\t%d,\n', 64);
        for i_c=1:64
            fprintf(fid, '\t\ttexture{pigment{rgb <%10.6f, %10.6f, %10.6f>}}\n', ...
                colmap(i_c,1), colmap(i_c,2), colmap(i_c,3));
        end
        fprintf(fid,'\t}\n\n');
    end
    
    fprintf(fid,'\tface_indices {\n');
    fprintf(fid,'\t\t%d,\n',size(hh.Faces,1));
    for i_f=1:N_faces
        fprintf(fid,'\t\t<%d, %d, %d>', ...
            hh.Faces(i_f, 1)-1, hh.Faces(i_f, 3)-1, hh.Faces(i_f, 2)-1);
        if isequal(pp.FaceColor, 'flat')
            min_z = min(hh.Vertices(hh.Faces(i_f,:),3));
            col_ind = round((min_z-col_range(1))/diff(col_range)*63);
            fprintf(fid,', %d',col_ind);
        elseif isequal(pp.FaceColor, 'interp')
            col_ind = nan(1,3);
            for i_v=1:3
                z = hh.Vertices(hh.Faces(i_f,i_v),3);
                col_ind(i_v) = round((z-col_range(1))/diff(col_range)*63);
            end
            fprintf(fid,', %d, %d, %d', col_ind(1),  col_ind(3),  col_ind(2));
        end
        if i_f ~= N_faces
            fprintf(fid,',\n');
        else
            fprintf(fid,'\n');
        end
    end
    fprintf(fid,'\t}\n');
    
    if ~any(isnan(facecolor))
        fprintf(fid,'\tpigment{rgb <%10.6f, %10.6f, %10.6f>}\n', ...
            facecolor(1), facecolor(2), facecolor(3));
    end
    if isfield(povray_options, 'Texture')
        fprintf(fid,'\ttexture { %s }\n', povray_options.Texture);
    end
    if isfield(povray_options, 'InteriorTexture')
        fprintf(fid,'\tinterior_texture  { %s }\n', povray_options.InteriorTexture);
    end
    fprintf(fid,'}\n\n');
    
    if isfield(povray_options, 'MeshOn') && povray_options.MeshOn        
        linecolor = [0 0 0];
        meshwidth = 0.02;
        
        [Nx, Ny] = size(pp.XData);
        xx = pp.XData(1,:);
        for i_y = 1:Nx
            yy = pp.YData(i_y, 1) * ones(size(xx));
            zz = pp.ZData(i_y, :);
            
            fprintf(fid,'sphere_sweep {\n');
            fprintf(fid,'\tlinear_spline\n');
            fprintf(fid,'\t%d,\n',Ny);
            for i_pt=1:Ny
                fprintf(fid,'\t<%10.6f, %10.6f, %10.6f>, %d\n', ...
                    xx(i_pt), zz(i_pt), yy(i_pt), meshwidth);
            end
            fprintf(fid,'\ttolerance 0.001\n');
            fprintf(fid,'\tpigment{rgb <%10.6f, %10.6f, %10.6f>}\n', ...
                linecolor(1), linecolor(2), linecolor(3));
            fprintf(fid,'}\n\n');
        end
        
        yy = pp.YData(:,1);
        for i_x = 1:Ny
            xx = pp.XData(1, i_x) * ones(size(yy));
            zz = pp.ZData(:, i_x);
            
            fprintf(fid,'sphere_sweep {\n');
            fprintf(fid,'\tlinear_spline\n');
            fprintf(fid,'\t%d,\n',Nx);
            for i_pt=1:Nx
                fprintf(fid,'\t<%10.6f, %10.6f, %10.6f>, %d\n', ...
                    xx(i_pt), zz(i_pt), yy(i_pt), meshwidth);
            end
            fprintf(fid,'\ttolerance 0.001\n');
            fprintf(fid,'\tpigment{rgb <%10.6f, %10.6f, %10.6f>}\n', ...
                linecolor(1), linecolor(2), linecolor(3));
            fprintf(fid,'}\n\n');
        end
        
        
    end
end

% Loop over Line objects
for i_l = 1:numel(line_obj)
    pp = line_obj(i_l);
    if isempty(pp.ZData)
        zdata = zeros(size(pp.XData));
    else
        zdata = pp.ZData;
    end
    if isfield(pp.('UserData'),'povray')
        povray_options = pp.('UserData').('povray');
    else
        povray_options = struct();
    end
    if isfield(povray_options, 'Color')
        linecolor = povray_options.Color;
    else
        linecolor = pp.Color;
    end
    if isfield(povray_options, 'SmoothingOn')
        smoothing_on = povray_options.SmoothingOn;
    else
        smoothing_on = false;
    end
        
    Npts = length(pp.XData);
    width = line_basewidth * pp.LineWidth;
    
    fprintf(fid,'sphere_sweep {\n');
    if smoothing_on
        fprintf(fid,'\tcubic_spline\n');
        fprintf(fid,'\t%d,\n',Npts+2);
        pt1 = [ pp.XData(1), zdata(1), pp.YData(1)];
        pt2 = [ pp.XData(2), zdata(2), pp.YData(2)];
        pt0 = pt1 + 0.1*(pt1-pt2)/norm(pt1-pt2);
        fprintf(fid,'\t<%10.6f, %10.6f, %10.6f>, %d\n', ...
            pt0(1), pt0(3), pt0(2), width);
    else
        fprintf(fid,'\tlinear_spline\n');
        fprintf(fid,'\t%d,\n',Npts);
    end
    for i_p=1:Npts
        fprintf(fid,'\t<%10.6f, %10.6f, %10.6f>, %d\n', ...
            pp.XData(i_p), zdata(i_p), pp.YData(i_p), width);
    end
    if smoothing_on
        pt1 = [ pp.XData(end-1), zdata(end-1), pp.YData(end-1)];
        pt2 = [ pp.XData(end), zdata(end), pp.YData(end)];
        pt0 = pt2 + 0.1*(pt2-pt1)/norm(pt2-pt1);
        fprintf(fid,'\t<%10.6f, %10.6f, %10.6f>, %d\n', ...
            pt0(1), pt0(3), pt0(2), width);
    end
    fprintf(fid,'\ttolerance 0.001\n');
    fprintf(fid,'\tpigment{rgb <%10.6f, %10.6f, %10.6f>}\n', ...
        linecolor(1), linecolor(2), linecolor(3));
    if isfield(povray_options, 'Texture')
        fprintf(fid,'\ttexture { %s }\n', povray_options.Texture);
    end   
    fprintf(fid,'}\n\n');
end

fclose(fid);
