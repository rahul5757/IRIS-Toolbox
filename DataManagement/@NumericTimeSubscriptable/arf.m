% Type `web Series/arf.md` for help on this function
%
% -IRIS Macroeconomic Modeling Toolbox
% -Copyright (c) 2007-2021 IRIS Solutions Team

% >=R2019b
%(
function this = arf(this, A, Z, range, options)

arguments
    this 
    A (1, :) double
    Z 
    range (1, :) {validate.mustBeProperRange} 

    options.PrependInput (1, 1) logical = false
    options.AppendInput (1, 1) logical = false
end
%)
% >=R2019b

% <=R2019a
%{
function this = arf(this, A, Z, range, varargin)

persistent parser
if isempty(parser)
    parser = extend.InputParser();
    addRequired(parser, 'x', @(x) isa(x, 'NumericTimeSubscriptable'));
    addRequired(parser, 'A', @isnumeric);
    addRequired(parser, 'Z', @(x) validate.numericScalar(x) || isa(x, 'NumericTimeSubscriptable'));
    addRequired(parser, 'Range', @validate.properRange);
    addParameter(parser, 'PrependInput', false, @validate.logicalScalar);
    addParameter(parser, 'AppendInput', false, @validate.logicalScalar);
end%
options = parse(parser, this, A, Z, range, varargin{:});
%}
% <=R2019a

range = double(range);
A = reshape(A, 1, []);
order = numel(A) - 1;

if range(1)<=range(end)
    time = "forward";
    extdRange = range(1)-order : range(end);
else
    time = "backward";
    extdRange = range(end) : range(1)+order;
end
numExtdPeriods = length(extdRange);

% Get endogenous data
dataX = getData(this, extdRange);
sizeX = size(dataX);
dataX = dataX(:, :);

% Get exogenous (z) data
if isa(Z, 'NumericTimeSubscriptable')
    dataZ = getData(Z, extdRange);
else
    dataZ = Z;
    if isempty(dataZ)
        dataZ = 0;
    end
    dataZ = repmat(dataZ, numExtdPeriods, 1);
end
sizeZ = size(dataZ);
dataZ = dataZ(:, :);

% Expand dataZ or dataX in 2nd dimension if needed
if size(dataZ, 2)==1 && size(dataX, 2)>1
    dataZ = repmat(dataZ, 1, size(dataX, 2));
elseif size(dataZ, 2)>1 && size(dataX, 2)==1
    dataX = repmat(dataX, 1, size(dataZ, 2));
    sizeX = sizeZ;
end

% Normalise polynomial vector
if A(1)~=1
    dataZ = dataZ / A(1);
    A = A / A(1);
end

% Set up time vector
if time=="forward"
    shifts = -1 : -1 : -order;
    timeVec = 1+order : numExtdPeriods;
else
    shifts = 1 : order;
    timeVec = numExtdPeriods-order : -1 : 1;
end


% /////////////////////////////////////////////////////////////////////////
for t = timeVec
    dataX(t, :) = -A(2:end)*dataX(t+shifts, :) + dataZ(t, :);
end
% /////////////////////////////////////////////////////////////////////////


newStart = extdRange(1);

if options.PrependInput
    [dataX, newStart] = herePrependData(dataX, newStart);
end

if options.AppendInput
    dataX = hereAppendData(dataX);
end

% Reshape output data back
if numel(sizeX)>2
    dataX = reshape(dataX, [size(dataX, 1), sizeX(2:end)]);
end

% Create the output series from the input series
this = fill(this, dataX, newStart);

return

    function [dataX, newStart] = herePrependData(dataX, newStart)
        %(
        prependData = getDataFromTo(this, -Inf, dater.plus(extdRange(1), -1));
        if size(prependData, 2)==1 && size(dataX, 2)>1
            prependData = repmat(prependData, 1, size(dataX, 2));
        end
        dataX = [prependData; dataX];
        newStart = dater.plus(newStart, -size(prependData, 1));
        %)
    end%

    function dataX = hereAppendData(dataX)
        %(
        appendData = getDataFromTo(this, dater.plus(extdRange(end), +1), Inf);
        if size(appendData, 2)==1 && size(dataX, 2)>1
            appendData = repmat(appendData, 1, size(dataX, 2));
        end
        dataX = [dataX; appendData];
        %)
    end%
end%

