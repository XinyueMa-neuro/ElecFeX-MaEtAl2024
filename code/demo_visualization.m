%% load a entry from excel file
dataFolder = '';
excelfn = '20230723_210859_X4PS_SupraThresh_DA_0.xlsx';

tb = readtable([dataFolder,excelfn],"ReadRowNames",true,'Sheet','Sheet1', 'ReadVariableNames',true); 
tb_header = readtable([dataFolder,excelfn],"ReadRowNames",true,'Sheet','Sheet1', 'ReadVariableNames',false,'Range','1:1'); 

%% input the known cluster (if any)
% meta file 
DataInfo_File = [dataFolder, '2021-09-13_mouse_file_ephys.xlsx'];
tb_info = readtable(DataInfo_File, "ReadRowNames", false); 

% get data file name
NWBfn = extractAfter(tb_header{1,:}, 'NWB_analysis\');
idx = cellfun(@(x)find(ismember(tb_info.file_name, x) ), NWBfn, 'UniformOutput',false);
NWBidx = [idx{:}];
NWBdonor = tb_info.donor_name(NWBidx);

% select mouselines
typelist = {'Pvalb-IRES-Cre;Ai14-', 'Vip-IRES-Cre;Ai14-'}; % ,'Sst-IRES-Cre;Ai14-'
NWBtype = zeros([1 length(NWBdonor)]);
for ii = 1:length(typelist)
     NWBtype( cellfun(@(x)startsWith(x, typelist{ii}), NWBdonor) ) = ii;
     fprintf('%s: cell number %d\n',typelist{ii}, sum(NWBtype==ii))
end

%% get a electrical property's value from the excel output
ii = 1;
y = table2array(tb(ii,:));
yname = tb.Properties.RowNames{ii};
disp(yname)

%% histogram plot
colorrgb = {
    [0.1922    0.3686    0.1490;  0.2039         0    0.0078], ... % dark green, dark orange
    [0.7961    0.9765    0.0078;  1.0000    0.6471         0], ... % light green, light orange 
    };

figure('Position',[0,0,800,200])
for ii = 1:length(typelist)
    hAxis = subplot(1, length(typelist), ii);
    histogram(y(NWBtype == ii),'FaceColor',colorrgb{2}(ii,:),'EdgeColor',colorrgb{1}(ii,:),'LineWidth',1,...
                'Normalization','probability', 'BinEdges',linspace( min(y), max(y), 20) ); 
    box off; 
    ylim([0,0.5]); 
    yticks([0,0.5]); 
    title(typelist{ii})
    xlabel(yname,'Interpreter','none'); 
    ylabel('%');   
end

%% violin plot
% the function 'violinplot' is adopted from https://github.com/bastibe/Violinplot-Matlab
figure('Position',[0,0,800,200])
   
violinplot( y(NWBtype~=0), NWBtype(NWBtype~=0), 'ViolinColor',colorrgb{2}(1:2,:),...
    'MarkerSize',5,'EdgeColor',[0,0,0],'ShowMedian',false,'ShowMean',false,'Showbox',false,'ViolinAlpha',{0.1 0.1});
xticklabels(typelist); ylabel(yname,'Interpreter','none')