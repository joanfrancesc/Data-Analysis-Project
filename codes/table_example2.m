% Define 2 column vectors of random numbers and chars
feat1 = randn(10, 1);
feat1(7) = inf;
feat2 = randi(150, [10, 1]);
feat2(2) = NaN;
feat3 = char(randi([48 90], [10, 5]));
feat3(5,:) = '-';

% Put them in a table and export it to a CSV file
df = table(feat1, feat2, feat3, 'VariableNames', ...
           {'FloatNumber', 'IntegerNumber', 'Text'});
writetable(df, 'data.csv')
