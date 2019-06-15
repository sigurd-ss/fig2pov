function pp_out = polyhedron_edges(pp_in, varargin)

options.sorted = true;

for kk=1:2:numel(varargin)
    if isfield(options, lower(varargin{kk}))
        options.(lower(varargin{kk})) = varargin{kk+1};
    end
end

[num_faces, Lface] = size(pp_in.Faces);

f_temp = zeros(num_faces*2, Lface);
f_temp(1:2:end,:) = pp_in.Faces;
f_temp(2:2:end,:) = circshift(pp_in.Faces, [0 1]);
if options.sorted
    all_edges = unique(sort(reshape(f_temp,2,[]),1)','rows');
else
    all_edges = unique(reshape(f_temp,2,[])','rows');
end
[inds_nan, ~] = find(isnan(all_edges));
all_edges(inds_nan,:) = [];

pp_out.Edges = all_edges;
pp_out.Vertices = pp_in.Vertices;