%% compare overlap
%% Match indentified cluster to genotype
clear TP TN FP FN Sens Spec Prec clustgp clustnum

for ic = 1:NClustBest
    ClustPredIdx = idxClust == ic;
    Jsim = []; % Jaccard similarity
    for ig = 1:length(typelist)
        Jsim(ig) = sum( ClustKnowIdx(ig,:) & ClustPredIdx ) / sum( ClustKnowIdx(ig,:) | ClustPredIdx );
    end
    [~, indmax] = max(Jsim);
    clustnum(ic) = sum(ClustPredIdx); %  cell number in predicted cluster
    clustgp{ic} = typelist{indmax}; % putative cell cluster
end

for ig = 1:length(typelist)
    cidx = find(strcmp(clustgp, typelist{ig}));
    ClustPredIdx = ismember(idxClust, cidx);
    %% count accuracy
    TP(ig) = sum( ClustPredIdx & ClustKnowIdx(ig,:) ) ;
    TN(ig) = sum( ~ClustPredIdx & ~ClustKnowIdx(ig,:) ) ;
    FP(ig) = sum( ClustPredIdx & ~ClustKnowIdx(ig,:) ) ;
    FN(ig) = sum( ~ClustPredIdx & ClustKnowIdx(ig,:) )  ;
    Sens(ig) = TP(ig)/(TP(ig)+FN(ig))*100;
    Spec(ig) = TN(ig)/(TN(ig)+FP(ig))*100;
    Prec(ig) = TP(ig)/(TP(ig)+FP(ig))*100;

    fprintf('>>> %s: %d predicted cluster(s) found.\n',typelist{ig},length(cidx))
    fprintf('Sensitivity: %.2f%%\n',TP/(TP+FN)*100)
    fprintf('Specificity: %.2f%%\n',TN/(TN+FP)*100)
    fprintf('Precision: %.2f%%\n',TP/(TP+FP)*100)
end