function [singals, singalTags, frequencySample] = loadRhythmsData(dbName, records, windowSizeInSecond)
    if isempty(dbName)
        error("dbName is empty");
    end
    if isempty(records)
        error("records is empty");
    end
    if isempty(windowSizeInSecond) || windowSizeInSecond <= 0
        error("windowSizeInSecond is empty or equal or less than zero");
    end
    if size(records, 1) ~= 1
        records = records';
    end

    selectedChannelNumber = 1;
    singalsAux = [];
    singalTagsAux = {};
    lastFrequencySample = 0;
    for record = records
        recordPath = char(strcat(dbName, '/', int2str(record)));

        [signal, fs] = rdsamp(recordPath, 1);
        if (lastFrequencySample == 0)
            lastFrequencySample = fs;
        elseif (lastFrequencySample ~= fs)
            error("Frequência de amostragem das amostras são difentes");
        end
        [ann,~,~,~,~,rhythms] = rdann(recordPath, 'atr');

        indexOfNotEmptyRhythms = find(~cellfun(@isempty, rhythms));
        numberOfSamplePerWindow = ceil(fs * windowSizeInSecond);
        for indexOfNotEmptyRhythm = indexOfNotEmptyRhythms'
            startSampleNumber = ann(indexOfNotEmptyRhythm);
            endSampleNumber = ann(indexOfNotEmptyRhythms(find(indexOfNotEmptyRhythms>indexOfNotEmptyRhythm, 1)));
            
            if isempty(endSampleNumber)
                endSampleNumber = ann(end);
            end

            window = endSampleNumber - startSampleNumber;
            if window < 0
                continue;
            end

            for sampleCount = 0:floor(window/(numberOfSamplePerWindow/2)-2)
                startSample = startSampleNumber + numberOfSamplePerWindow/2*sampleCount;
                endSample = startSample + numberOfSamplePerWindow - 1;
         
                nonNormalizedSignal = signal(startSample:endSample, selectedChannelNumber);
                singalsAux = [singalsAux nonNormalizedSignal/max(nonNormalizedSignal)];
                singalTagsAux = [singalTagsAux rhythms(indexOfNotEmptyRhythm)];
            end
        end
    end

    singals = singalsAux;
    singalTags = singalTagsAux;
    frequencySample = lastFrequencySample;
end