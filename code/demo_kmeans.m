%% choose the "criteria", "Distance", "Start" to perform K-means cluster
kcrite_all = {'DaviesBouldin', 'CalinskiHarabasz','silhouette'};
clt_dis_all = {'cosine', 'sqeuclidean','correlation'};
startM_all = {'plus','cluster','sample','uniform'};

clt_dis = clt_dis_all{1};
startM = startM_all{1};
kCrite = kcrite_all{1};
NClustBest = 2;

[idxClust, NClustBest] = getCluster(mytable_PCA_zscore, 'kDistance',clt_dis,'kMaxIter',5000,'kMaxN',20,'kMinN',2,'kIterN',50,...
    'RandSeed',4,'kStart',startM,'IfDispAllSil',1,'IfDispBestSil',1,'NClustBest',NClustBest,'kCriterion',kCrite); %

for ii = 1:length(typelist)
    ClustKnowIdx(ii,:) = [NWBtype(NWBtype~=0) == ii];
    plotCluster(mytable_PCA_zscore,idxClust,'tsne','rngClust',5,'rngColor',6,'tDistance','euclidean', ...
            'ClustKnowIdx',ClustKnowIdx(ii,:),'ClustPredIdx',[],'ClustKnowLabel',typelist{ii})
end

function [idxClust, NClustBest] = getCluster(mPCA, Params)
    arguments
        mPCA % PCA component matrix. Column-Components | Row-Objects
       
        Params.RandSeed = 1
        Params.NClustBest {mustBeInteger} = 0;  % if 0, find the optimal cluster number
        %% Kmeans Parameter Settings
        % -- kmeans() 
        Params.kDistance {mustBeMember(Params.kDistance, {'sqeuclidean','cityblock','cosine','correlation','hamming'})} = 'cosine' 
        Params.kCriterion {mustBeMember(Params.kCriterion, {'DaviesBouldin','silhouette','CalinskiHarabasz'})} = 'DaviesBouldin' 
        Params.kMaxIter {mustBePositive} = 3000
        Params.kStart {mustBeMember(Params.kStart, {'plus','cluster','sample','uniform'})} = 'sample'
        % -- kmeans: find optimal cluster number        
        Params.kMinN = 5                        % maximal cluster number to test
        Params.kMaxN = 20                       % maximal cluster number to test
        Params.kIterN = 20;                     % repeat time
        % -- kmeans: visualization
        Params.IfDispAllSil = 0;
        Params.IfDispBestSil = 0;

    end

    rng(Params.RandSeed)

    %% Kmeans cluster
        mykmean = @(x, k) kmeans(x,k,'Distance',Params.kDistance,'MaxIter',Params.kMaxIter,'Start',Params.kStart);
        
        % find optimal cluster number 
        if ~Params.NClustBest
            sil = []; meansil = [];
            klist = Params.kMinN:Params.kMaxN;
            parfor irand = 1:Params.kIterN
                rng(irand+5)
                eva = evalclusters(mPCA,mykmean,Params.kCriterion,'klist',klist);
                sil(irand, :) = eva.CriterionValues;
            end
            meansil = mean(sil,1);
            if strcmp(Params.kCriterion, 'DaviesBouldin')
                [~, ind_NclustBest] = min(meansil);
            else
                [~, ind_NclustBest] = max(meansil);
            end
            NClustBest = klist(ind_NclustBest);
        else
            NClustBest = Params.NClustBest;
        end

        % kmeans cluster
        idxClust_trial = [];
        s_trial = [];
        for ii = 1:Params.kIterN
            idxClust_trial(ii,:) = mykmean(mPCA,NClustBest);
            eva = evalclusters(mPCA,idxClust_trial(ii,:)',Params.kCriterion);
            s_trial(ii) = eva.CriterionValues;
        end
        if strcmp(Params.kCriterion, 'DaviesBouldin')
            [~, ind_max] = min(s_trial);
        else
            [~, ind_max] = max(s_trial);
        end
        idxClust = idxClust_trial(ind_max,:);

        % -- visualization
        if Params.IfDispAllSil && ~Params.NClustBest    
            figure('Position',[0,0,400,300]); 
            plot(klist, meansil,'k.-','LineWidth',1,'MarkerSize',8); hold on;
            [px, py] = getpatch(klist,sil,'sem');
            p = patch(px, py, [0.8, 0.8, 0.8],'EdgeColor','none'); uistack(p,'bottom')
            plot(NClustBest, meansil(ind_NclustBest),'pr','MarkerFaceColor','r','MarkerSize',7)
            ylabel('average silhouette score'); xlabel('Number of clusters')
            title(['Peak at ',num2str(NClustBest),' clusters']);
        end

        if Params.IfDispBestSil
            figure('position',[0,0,400,300])
            silhouette(mPCA,idxClust);
        end
end

function plotCluster(mPCA, idxClust, Method, Params)
    arguments
        mPCA % PCA component matrix. Column-Components | Row-Objects
        idxClust % object cluster index
        Method {mustBeMember(Method, {'pca','tsne'})} = 'tsne'
        Params.rngColor = 1;
        Params.rngClust = 1;
        Params.ClustLabel = {};
        % -- tSNE parameter setting
        Params.tDistance {mustBeMember(Params.tDistance,{'euclidean','seuclidean',...
            'fasteuclidean','fastseuclidean','cityblock','chebychev','minkowski',...
            'mahalanobis','cosine','correlation','spearman','hamming','jaccard'})} ...
            = 'mahalanobis'
        % -- pca parameter setting
        Params.pMaxIter = 2000;
        Params.pAlgo {mustBeMember(Params.pAlgo, {'svd','eig','als'})} = 'svd' 
        % -- (optional) compare between identified cluster and known cluster
        Params.ClustPredIdx = []; % 0/1 array; red-filled square
        Params.ClustKnowIdx = []; % 0/1 array; black-edge square
        Params.ClustKnowLabel = 'know';
        % other datapoints are grey-filled circle
    end
    
    % cluster color
    rng(Params.rngColor); 
    ncluster = length(unique(idxClust));
    randcolor = rand([ncluster,3]);
    
    
    % cluster
    rng(Params.rngClust); 
    switch Method
        case 'pca'
            opt = statset('pca'); 
            opt.MaxIter = Params.pMaxIter; 
            [~,Y] = pca(mPCA,'Options', opt,'Algorithm',Params.pAlgo);
        case 'tsne'
            % tSNE
            Y = tsne(mPCA,'Distance',Params.tDistance);
    end
    
    % cluster range
    myxlim = [min(Y(:,1)), max(Y(:,1))] + [-0.09, 0.09]*(max(Y(:,1))-min(Y(:,1)));
    myylim = [min(Y(:,2)), max(Y(:,2))] + [-0.09, 0.09]*(max(Y(:,2))-min(Y(:,2)));
    
    % visualization
    figure('Position',[0,0,700,300]);
    subplot(1,2,1)
    gsc_all = gscatter(Y(:,1),Y(:,2),idxClust,randcolor,'.',15);
    if isempty(Params.ClustLabel)
        legend('Location','best')
    else
        legend(Params.ClustLabel,'Location','best')
    end
    xlabel('t-SNE 1'); ylabel('t-SNE 2')
    box off; xticks([]); yticks([]); xlim(myxlim); ylim(myylim);
    
    subplot(1,2,2)
    mygray = [0.77 0.77 0.77];
    if ~isempty(Params.ClustPredIdx) && ~isempty(Params.ClustKnowIdx)
        idx_both = (Params.ClustPredIdx & Params.ClustKnowIdx);
        idx_bg = ~(Params.ClustPredIdx | Params.ClustKnowIdx);
        idx_PredOnly = Params.ClustPredIdx & ~Params.ClustKnowIdx;
        idx_KnowOnly = ~Params.ClustPredIdx & Params.ClustKnowIdx;
    end
    if isempty(Params.ClustPredIdx) && isempty(Params.ClustKnowIdx)
        return
    end
    if isempty(Params.ClustKnowIdx) && ~isempty(Params.ClustKnowIdx)
        idx_both = logical(zeros(size(Y))); 
        idx_bg = ~Params.ClustPredIdx;
        idx_PredOnly = Params.ClustPredIdx;
        idx_KnowOnly = logical(zeros(size(Y))); 
    end
    if isempty(Params.ClustPredIdx) && ~isempty(Params.ClustKnowIdx)
        idx_both = logical(zeros(size(Y))); 
        idx_bg = ~Params.ClustKnowIdx;
        idx_PredOnly =logical( zeros(size(Y))); 
        idx_KnowOnly = Params.ClustKnowIdx;
    end
    plot(Y(idx_bg,1),Y(idx_bg,2),'Color',mygray,'MarkerFaceColor',mygray,'Marker','o','LineStyle','none','HandleVisibility','off'); hold on
    plot(Y( find( idx_KnowOnly) ,1),Y(find( idx_KnowOnly),2),'Color','k','MarkerFaceColor',mygray,'Marker','s','LineStyle','none');
    plot(Y(idx_PredOnly,1),Y(idx_PredOnly,2),'Color',mygray,'MarkerFaceColor','r','Marker','s','LineStyle','none');
    plot(Y(idx_both,1),Y(idx_both,2),'Color','k','MarkerFaceColor','r','Marker','s','LineStyle','none');
    % title(Params.ClustKnowLabel)
    legend({Params.ClustKnowLabel,'predict','overlap'},'Location','best')
    
    xlabel('t-SNE 1'); ylabel('t-SNE 2')
    box off; xticks([]); yticks([]); xlim(myxlim); ylim(myylim);



end
