%% Load data
% close all;
% clear;
% clc;
% 
% addpath("Functions/");
% 
% dbName = "mitdb";
% records = [102 106 119 124 200 201 207 222 223 230 231 232];
% windowSizeInSecond = 4;
% 
% [rawSingals, rawSingalTags] = loadRhythmsData(dbName, records, windowSizeInSecond);
% 
% save('data/rawSingals.mat', 'rawSingals', 'rawSingalTags');

%% Get data
close all;
clear;
clc;

addpath("Functions/");

rawData = load('data/rawSingals.mat');
desiredRhythms = ["(B" "(T" "(N" "$"]; % Use "$" to another rhythms
desiredAmountOfEachRhythm = [200 200 200 400];
[singals, singalTags] = getSelectedRhythmsData(rawData.rawSingals, rawData.rawSingalTags, desiredRhythms, desiredAmountOfEachRhythm);
save('data/singals.mat', 'singals', 'singalTags');

%% Signal Analysis

% Wavelet Packet
close all;
clear;
clc;

data = load('data/singals.mat');

waveletLevel = 3;
% waveletName = "db4";
% waveletName = "sym4";
waveletName = "coif3";

[WPT,~,PACKETLEVELS,~,RE] = dwpt(data.singals, waveletName,'Level', waveletLevel, 'FullTree', true);

% Extract Fetures from wavelet
% Estrutura para das caracteristicas
% "(B" "(T" "N" (rhythms)
% 2.2   43  121 (relative energy)
% 2.2   43  121 (Entropy)
% 2.2   43  121 (maxValue)
% 2.2   43  121 (minValue)
% Os cada possição de caracteristica conterá os valores dos niveis do WPT

numberOfCaracteres = 4;
feturesExtracteds = cell(numberOfCaracteres+1,length(data.singalTags));
for singalIndex = 1:length(data.singalTags)
    feturesExtracteds{1, singalIndex} = data.singalTags(singalIndex);
    for levelIndex = find(PACKETLEVELS==waveletLevel)'
        % Using Relative Energy
        feturesExtracteds{2,singalIndex} = [feturesExtracteds{2,singalIndex} RE{levelIndex}(singalIndex)];
        
        % Using Entropy
        entropy = getEntropy(WPT{levelIndex}(singalIndex,:));
        feturesExtracteds{3,singalIndex} = [feturesExtracteds{3,singalIndex} entropy];

        % Using MaxValue
        maxValue = max(WPT{levelIndex}(singalIndex,:));
        feturesExtracteds{4,singalIndex} = [feturesExtracteds{4,singalIndex} maxValue];

        % Using MinValue
        minValue = min(WPT{levelIndex}(singalIndex,:));
        feturesExtracteds{5,singalIndex} = [feturesExtracteds{5,singalIndex} minValue];
    end
end

save('data/feturesExtracteds.mat', 'feturesExtracteds', 'numberOfCaracteres');

% SVM
close all;
clear;
clc;

data = load('data/feturesExtracteds.mat');

testRadioInPorcentage = 20;
X_train = [];
y_train = [];
X_test = [];
y_test = [];

for class = unique(string(data.feturesExtracteds(1,:)))
    index = find(ismember(string(data.feturesExtracteds(1,:)), class));
    testAmount = ceil(length(index) * (testRadioInPorcentage/100));
    X_test = [X_test; cell2mat(data.feturesExtracteds(2:data.numberOfCaracteres+1, index(1:testAmount))')];
    y_test = [y_test; string(data.feturesExtracteds(1,index(1:testAmount))')];

    X_train = [X_train; cell2mat(data.feturesExtracteds(2:data.numberOfCaracteres+1, index(testAmount+1:end))')];
    y_train = [y_train; string(data.feturesExtracteds(1,index(testAmount+1:end))')];
end

% Trainning One Against All
classes = unique(y_train);
SVMModels = cell(length(classes),1);
rng(1); % For reproducibility

for j = 1:numel(classes)
    indx = strcmp(y_train,classes(j)); % Create binary classes for each classifier
    SVMModels{j} = fitcsvm(X_train,indx,'ClassNames',[false true],'Standardize',true,...
        'KernelFunction','rbf','BoxConstraint',1);
end

N = size(X_test,1);
Scores = zeros(N,numel(classes));

for j = 1:numel(classes)
    [~,score] = predict(SVMModels{j},X_test);
    Scores(:,j) = score(:,2); % Second column contains positive-class scores
end

[~,testResponses] = max(Scores,[],2);

% Compare
correctAnswerCount = 0;
confusionMatrix = zeros(numel(classes), numel(classes));
for i = 1:numel(testResponses)
    predValue = testResponses(i);
    correctValue = find(classes==y_test(i), 1);
    if correctValue == predValue
        correctAnswerCount = correctAnswerCount + 1;
    end
    
    confusionMatrix(correctValue, predValue) = confusionMatrix(correctValue, predValue) + 1;
end

accuracy = correctAnswerCount/numel(y_test);

%% Util

% Plot valuesd
BIndex = find(strcmp(y_train, '(B'));
figure
plot3(X_train(BIndex,1),X_train(BIndex,2),X_train(BIndex,3),'or')
hold on
NIndex = find(strcmp(y_train, '(N'));
plot3(X_train(NIndex,1),X_train(NIndex,2),X_train(NIndex,3),'ob')
hold on
TIndex = find(strcmp(y_train, '(T'));
plot3(X_train(TIndex,1),X_train(TIndex,2),X_train(TIndex,3),'oy')
hold on
DIndex = find(strcmp(y_train, '$'));
plot3(X_train(DIndex,1),X_train(DIndex,2),X_train(DIndex,3),'ok')
hold off



