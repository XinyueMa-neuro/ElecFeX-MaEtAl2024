%% optimal cluster number
kcrite_all = {'DaviesBouldin', 'CalinskiHarabasz','silhouette'};
clt_dis_all = {'cosine', 'sqeuclidean','correlation'};
startM_all = {'plus','cluster','sample','uniform'};

krange = [2:min([20, size(mytable_PCA_zscore,2)-10])];

kcrite = kcrite_all{1};

figure();
for ii = 1:length(clt_dis_all)
    for jj = 1:length(startM_all)   
        mykmean = @(x, k) kmeans(x,k,'Distance',clt_dis_all{ii},'MaxIter',1000,'Start',startM_all{jj});
        mytable_PCA_zscore = real(mytable_PCA_zscore);
        sval = [];
        parfor kk = 1:20 % repeat for 20 times
            rng(kk+6)
            eva = evalclusters(mytable_PCA_zscore,mykmean,kcrite,'klist',krange);
            sval(kk,:) = rescale(eva.CriterionValues);
        end
        sval_mean = mean(sval,1);
        
        subplot(length(clt_dis_all),length(startM_all),jj+(ii-1)*length(startM_all)); 

        [px, py] = getpatch(krange,sval,'sem');
        p = patch(px, py, [0.8, 0.8, 0.8],'EdgeColor','none'); uistack(p,'bottom'); hold on

        plot(krange, sval_mean,'k-'); title([clt_dis_all{ii},' ', startM_all{jj}]); 
        [~, indmin] = min(sval_mean);
        plot(krange(indmin), sval_mean(indmin),'rp')

    end
end
sgtitle(kcrite)


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