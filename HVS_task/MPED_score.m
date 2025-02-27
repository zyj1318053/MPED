function score=SPED_score_v(pc_ori,pc_dis,pc_fast,k,distance_type, color_type, T)
if k<1
    error('the numebr of neighbors should be bigger than 1!');
end


count = pc_fast.Count;

center_coordinate = pc_fast.Location;
source_coordinate = pc_ori.Location;
target_coordinate = pc_dis.Location;

center_color = single(pc_fast.Color);
source_color = single(pc_ori.Color);
target_color = single(pc_dis.Color);

LMN_matrix = [0.06,0.63,0.27;0.3,0.04,-0.35;0.34,-0.60,0.17]';
YUV_matrix = [0.299, 0.587,0.114;-0.1678,-0.3313,0.5;0.5,-0.4187,-0.0813]';


if color_type == 'RGB'
    center_color = single(pc_fast.Color);
    source_color = single(pc_ori.Color);
    target_color = single(pc_dis.Color);
elseif color_type == 'LMN'
    center_color = center_color * LMN_matrix ;
    source_color = source_color * LMN_matrix;
    target_color = target_color * LMN_matrix;
elseif color_type == 'YUV'
    center_color = center_color * YUV_matrix;
    source_color = source_color * YUV_matrix;
    target_color = target_color * YUV_matrix;
end


%% Neighborhood establish
[idx_source, dit_source] = knnsearch( source_coordinate, center_coordinate, 'k', k,  'distance', 'euclidean');
[idx_target, dit_target] = knnsearch( target_coordinate, center_coordinate, 'k', k,  'distance', 'euclidean');

%% Potential energy of each neighborhood
center_mass = center_color;
idx_source_T=idx_source';
idx_target_T=idx_target';
dit_source_T=dit_source';
dit_target_T=dit_target';
neighbor_source_mass = source_color(idx_source_T(:),:);
neighbor_target_mass = target_color(idx_target_T(:),:);
neighbor_source_coordinate = source_coordinate(idx_source_T(:),:);
neighbor_target_coordinate = target_coordinate(idx_target_T(:),:);
dis_square_source = (dit_source_T(:)).^2; 
dis_square_target = (dit_target_T(:)).^2; 

center_mass_rep = reshape(repmat(center_mass(:)',k,1),[],3);
source_mass_dif = abs(neighbor_source_mass-center_mass_rep);
target_mass_dif = abs(neighbor_target_mass-center_mass_rep);
if color_type == 'RGB'
    source_mass_dif = sqrt(1*source_mass_dif(:,1)+2*source_mass_dif(:,2)+1*source_mass_dif(:,3)+1);
    target_mass_dif = sqrt(1*target_mass_dif(:,1)+2*target_mass_dif(:,2)+1*target_mass_dif(:,3)+1);
else
    source_mass_dif = sqrt(6*source_mass_dif(:,1)+1*source_mass_dif(:,2)+1*source_mass_dif(:,3)+1);
    target_mass_dif = sqrt(6*target_mass_dif(:,1)+1*target_mass_dif(:,2)+1*target_mass_dif(:,3)+1);
end
center_coordinate_rep = reshape(repmat(center_coordinate(:)',k,1),[],3);
% distance between center and neighbor
source_coordinate_dif = neighbor_source_coordinate - center_coordinate_rep;
target_coordinate_dif = neighbor_target_coordinate - center_coordinate_rep;
if distance_type == '1-norm'
    source_distance_dif = sum(abs(source_coordinate_dif),2);
    target_distance_dif = sum(abs(target_coordinate_dif),2);
elseif distance_type == '2-norm'
    source_distance_dif = dis_square_source;
    target_distance_dif = dis_square_target;
else
    error('Wrong distance type! Please use 1-norm or 2-norm!');
end

if k==1
    g_source = 1;
    g_target = 1;
else
     g_source = 1./sqrt(source_distance_dif + 1);
     g_target = 1./sqrt(target_distance_dif + 1);

end

    energy_source = (source_mass_dif.* g_source.* source_distance_dif);
    energy_target = (target_mass_dif.* g_target.* target_distance_dif);
    energy_source_reshape = reshape(energy_source, k, count);
    energy_target_reshape = reshape(energy_target, k, count);
    energy_source_sum = sum(energy_source_reshape, 1);
    energy_target_sum = sum(energy_target_reshape, 1);
    
    energy_diff = sum(abs(energy_source_sum - energy_target_sum))/(count*k);
    
    resolution = sqrt(((sum(source_distance_dif)/(count*k))));

    score = energy_diff/resolution;
    
    
