% Type `web +databank/toArray.md` for help on this function
%
% -[IrisToolbox] for Macroeconomic Modeling
% -Copyright (c) 2007-2021 [IrisToolbox] Solutions Team

% >=R2019b
%(
function [outputArray, names, dates] = toArray(inputDb, names, dates, column)

arguments

    inputDb (1, 1) {validate.databank}
    names {locallyValidateNames} = @all
    dates {locallyValidateDates} = Inf


    % column  Vector of flat columns in 2nd and higher dimensions to
    % retrieve from the input time series; if column=0, all columns will
    % be retrieved or data with a single column expanded unless there is
    % inconsistency

    column (1, 1) double {mustBeNonnegative} = 1 

end
%)
% >=R2019b


% <=R2019a
%{
function [outputArray, names, dates] = toArray(inputDb, varargin)

persistent inputParser
if isempty(inputParser)
    inputParser = extend.InputParser("databank.toArray");
    addRequired(inputParser, "inputDb", @(x) validate.databank(x) && isscalar(x)); 
    addOptional(inputParser, "names", @all, @locallyValidateNames);
    addOptional(inputParser, "dates", @all, @locallyValidateDates);
    addOptional(inputParser, "column", 1, @(x) isnumeric(x) && all(x(:)==round(x(:))) && all(x(:)>=0));
end
parse(inputParser, inputDb, varargin{:});
names =  inputParser.Results.names;
dates = inputParser.Results.dates;
column = inputParser.Results.column;
%}
% <=R2019a


% Legacy value
if isequal(dates, @all)
    dates = Inf;
end

%
% Extract data as a cell array of numeric arrays
%
[data, names, dates] = databank.backend.extractSeriesData(inputDb, names, dates);

%
% Extract requested column
%
numData = numel(data);
if isequal(column, Inf)
    numColumns = [];
    for x = data
        sizeData = size(x{:});
        numColumns(end+1) = prod(sizeData(2:end));
    end
    maxColumns = max(numColumns);
    inxValid = numColumns==1 | numColumns==maxColumns;
    if any(~inxValid)
        exception.error([
            "Databank"
            "Inconsistent numbers of columns in 2nd and higher dimensions "
            "in these time series: " + join(names(numColumns~=1), " ")
        ]);
    end
    if maxColumns>1 && any(numColumns==1)
        for i = find(numColumns==1)
            data{i} = repmat(data{i}, 1, maxColumns);
        end
        for i = 1 : numData
            data{i} = reshape(data{i}, size(data{i}, 1), 1, []);
        end
    end
else
    for i = 1 : numData
        data{i} = data{i}(:, column);
    end
end

outputArray = [data{:}];

end%

%
% Local Validators
%

function flag = locallyValidateNames(x)
    %(
    flag = true;
    if isa(x, 'function_handle') || isstring(string(x))
        return
    end
    error("Input value must be an array of strings or a test function.");
    %)
end%


function flag = locallyValidateDates(x)
    %(
    flag = true;
    if isnumeric(x)
        return
    end
    if isequal(x, @all)
        return
    end
    if isstring(x) && ismember(x, ["balanced", "unbalanced"])
        return
    end
    error("Input value must be a date vector, an Inf range, or one of {""balanced"", ""unbalanced""}.");
    %)
end%

