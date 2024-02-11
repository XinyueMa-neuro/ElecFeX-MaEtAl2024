% - paremeter setting for revision
% selecting parameters similar to Gouwen et al. 2019, 2020
pcaTypes_kw = { {'SpikeNumber','TimeAtLastSpike', 'CVISI','AdaptIndex','FrequencyDecayRate'}, ...
               repmat({'APonset','APpeak','APoffset','SpikeThreshold'},[1 1]),... 
               repmat({'APmaxRiseSlope','APmaxFallSlope'},[1 1]),...
               repmat({'APriseTime','APfallTime','APduration','HalfWidth','BaseWidth'},[1 1]),...
};        

pcaTypes_name = {'spike train','AP voltage','AP slope','AP time',...
                 'SpikeThreshold','APwidths'};

mycolor = {
           '#7CBD9C', ... % green: feature     '#078442',
           '#000000',...
           '#89cff0',... %'#3388FF', '#0044FF', '#0E4C92' ... % blue: time series
           '#ffb3c6',... %'#FC94AF', '#FE7F9C', '#d24787' ... % pink: spike properties          
           };
ifplot = 1;
mytable_PCA_zscore = [];
mytable_PCA_allscore = [];
mytable_PCA_allz = [];
MaxComp = 12.5;
palpha = 0.3;
rng(1)
PCA_th = 80; % components of explained variance exceeding this value were remained

myfig = figure('Position',[0,0,800,400]); myaxes = gca(myfig);
ntype = length(pcaTypes_kw);
for itype = 1:ntype
    clear mypc 
    kw = pcaTypes_kw{itype};
    tb_sample = [];
    for ii = 1:length(kw)
        irow = find(contains(tb.Properties.RowNames, kw{ii})); % pcaTypes_irow{itype}(ii); 
        tb_sample = [tb_sample; table2array( tb(irow,NWBtype~=0) )];
    end
    % tb: row - variable | column - data

    % -- standardization by z-score
    % zscore() - the column of the data is centered | return NaN when column contains NaN
    tb_zscore = ( tb_sample - nanmean(tb_sample,2) ) ./ nanstd(tb_sample,[],2);
    tb_zscore = tb_zscore';
    % -- NaN missing value: replace by arbitrary number
    % tb_zscore(isnan(tb_zscore)) = NaNRep;

    % -- principle component analysis: dimension reduction (missing data)
    [coeff,score,latent,tsquared,explained,mu] = pca(tb_zscore,"Algorithm","als"); %,"Algorithm","als"
%     % -- Input: row - observation | column: variable
   
    %% explained variance exceeding the threshold
    explained_cum = cumsum(explained);
    pc_th = find(explained_cum >= PCA_th,1,'first');
    mypc = score(:,1:pc_th); % score; *coeff
    % mypc(imag(mypc)>0) = 0; % mypc complex double

    mytable_PCA_allz = [mytable_PCA_allz, tb_zscore];
    mytable_PCA_allscore = [mytable_PCA_allscore, score];
    mytable_PCA_zscore = [mytable_PCA_zscore, mypc];

    if ifplot
        xbar = 1:length(explained);
        % --- cummulative variance
        hold(myaxes, 'on');
        plot( myaxes, xbar, explained_cum,'-','Marker','.','Color',mycolor{itype},'LineWidth',1,'handlevisibility','off'); 
        p = plot( myaxes, xbar(1:pc_th), explained_cum(1:pc_th),'-','Marker','s','Color',mycolor{itype},'LineWidth',1,'MarkerFaceColor',mycolor{itype},'MarkerSize',7); 

%         hold(myaxes, 'off');

        % --- variance var plot
        hAxis = axes('Position',[0.3+(itype-1)*0.12 0.16 0.1 0.22],'Parent',myfig);
%         hAxis = subplot(1,ntype,itype,'Parent',fig_bar);
        hold(hAxis,'on')
        bar(hAxis, xbar(1:pc_th), explained(1:pc_th),'FaceColor',p.Color,'EdgeColor',p.Color,'FaceAlpha',0.9);
        bar(hAxis, xbar(pc_th:end), explained(pc_th:end),'FaceColor',p.Color,'EdgeColor','none','FaceAlpha',palpha); 
        set(hAxis,'YLim',[0,80],'XLim',[0,8])
        axis(hAxis,'off');
        hold(hAxis, 'off');
        hold(myaxes, 'off');
    end
end
if ifplot
    hold(myaxes, 'on')    
    box(myaxes, 'off');
    set(myaxes,'XLim',[0, MaxComp], 'YLim',[20,101]);
    title(myaxes,''); xlabel(myaxes,'Number of components'); ylabel(myaxes,'Cummulative explained variance (%)')
    plot(myaxes,[0,MaxComp],[PCA_th, PCA_th],'r--','LineWidth',1.5,'HandleVisibility','off')
    lgd = legend(myaxes,pcaTypes_name,'Location','northeastoutside');
    title(lgd,'Feature')
    hold(myaxes, 'off')
end

function [px, py] = getpatch(x, y, vartype)
    if strcmpi(vartype,'std')
        delta = nanstd(y,1);
    elseif strcmpi(vartype,'sem')
        delta = nanstd(y,1) ./ sqrt(size(y,1));
    end
    py_1 = nanmean(y,1)+delta; % /sqrt(length(nspike_ind{icond}))
    py_2 = flip(nanmean(y,1)-delta);
    px_1 = x; px_2 = flip(x);
    px_1(isnan(py_1)) = []; px_2(isnan(py_2)) = [];
    py_1(isnan(py_1)) = []; py_2(isnan(py_2)) = [];
    px = [px_1, px_2];
    py = [py_1, py_2];
end