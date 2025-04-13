% Define 2 column vectors of 5 random integers between 1 and 10
feat1 = randi(10, [5, 1]);
feat2 = randi(10, [5, 1]);
% Put vectors into table as if they were useful features
df = table(feat1, feat2, 'VariableNames', {'Feature1', 'Feature2'})
