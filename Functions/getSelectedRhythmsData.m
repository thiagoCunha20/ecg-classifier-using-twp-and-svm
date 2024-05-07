function [singals, singalTags] = getSelectedRhythmsData(rawSingals, rawSingalTags, desiredRhythms, desiredAmountOfEachRhythm)
    if isempty(desiredRhythms)
        error("desiredRhythms is empty");
    end
    if length(unique(desiredRhythms)) ~= length(desiredRhythms)
        error("desiredRhythms cannot have a duplicate value");
    end
    if isempty(desiredAmountOfEachRhythm)
        error("desiredAmountOfEachRhythm is empty");
    end
    if size(desiredRhythms, 1) ~= 1
        desiredRhythms = desiredRhythms';
    end
    if size(desiredAmountOfEachRhythm, 1) ~= 1
        desiredAmountOfEachRhythm = desiredAmountOfEachRhythm';
    end

    anotherRhythmsAnn = "$";
    indexOfselectedSignalTags = [];
    for desiredRhythm = desiredRhythms
        desiredAmount = desiredAmountOfEachRhythm(desiredRhythms == desiredRhythm);
        
        if desiredRhythm ~= anotherRhythmsAnn
            indexOfselectedSignalTags = [indexOfselectedSignalTags find(rawSingalTags == desiredRhythm, desiredAmount)];
        else
            indexOfAnotherRhythms = ~ismember(rawSingalTags, desiredRhythms);
            [uniqueSingalTags,~,ic] = unique(rawSingalTags(indexOfAnotherRhythms)');
            uniqueSingalTagCounts = accumarray(ic,1);
            minAmountPerTag = ceil(desiredAmount / length(uniqueSingalTags));

            if minAmountPerTag > min(uniqueSingalTagCounts)
                warning("não existe amostra suficiente para gerar uma base simetrica para " + desiredRhythm);
            end
            
            for uniqueSingalTag = uniqueSingalTags'
                indexOfselectedSignalTags = [indexOfselectedSignalTags find(rawSingalTags == string(uniqueSingalTag), minAmountPerTag)];
            end
        end
    end

    singals = rawSingals(:, indexOfselectedSignalTags);
    allSignalTags = rawSingalTags(:, indexOfselectedSignalTags);
    anotherRhythmSignal = ~ismember(allSignalTags, desiredRhythms);
    allSignalTags(anotherRhythmSignal) = cellstr(anotherRhythmsAnn);
    singalTags = allSignalTags;
end