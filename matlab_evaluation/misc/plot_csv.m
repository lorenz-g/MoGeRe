

% orig data
from_directory = '../raw_data/dataset_8_4_14/csvNoise_60Hz/';
% dir for the plots to be saved
to_directory = '../raw_data/dataset_8_4_14/csvNoisePlots/';

f = dir(from_directory);


% this is not perfect but it works. A binary mask would be nicer...
regex = '[\w]+(\.csv)$';
f = regexpi({f.name}, regex, 'match');
f = [f{:}];

% suppress that all the figures are shown...
set(0,'DefaultFigureVisible','off');

for i = 1: numel(f)
%for i = 1: 2
    [x,y,z,t] = read_lgdb_data([from_directory f{i}]);
 
    % plot name is a 1x2cell
    plotname = strsplit(f{i},'.');
    
    
    plot(t, x, 'r', t, y, 'g', t, z, 'b');
    % the underscore is interpreted by matlab
    title(strrep(f{i}, '_', ' '));
    legend('x axis','y axis','z axis');
    xlabel('time in s');
    ylabel('acceleration in g');

    saveas(gcf,[to_directory plotname{1}],'jpg')  
    
    % nice to know for large sets, where you are
    %plotname{1}
    
end

set(0,'DefaultFigureVisible','on');