function [f, IDX] = assign_to_cluster(C, cl_values, f)
% find euclidian distance to each point of C and the assign to point with
% min distance
IDX = zeros(size(cl_values, 1), 1);

% no of clusters
k = size(C, 1);

for i = 1: size(IDX, 1)
    min_dis = 10;
    for j = 1:k
        tmp_d = sqrt((cl_values(i,1) - C(j,1))^2 + ...
            (cl_values(i,2)- C(j,2))^2 + (cl_values(i,3)- C(j,3))^2);
        if tmp_d < min_dis
            min_dis = tmp_d;
            IDX(i,1) = j;
        end
    end
end
   

%% add the IDX values to f
%   IDX is an array of the clustered datapoints
tmp = 1;
for i = 1: (size(f,1))
    f(i, 6) = {IDX(tmp: (tmp + f{i,3} -1))};
    tmp = tmp + f{i,3};
end

end

