
% >=R2019b
%(
function [flag, listMissing, listSuspect] = checkInitials(this, inputDb, range, options)

arguments
    this Model
    inputDb {validate.mustBeDatabank}
    range {validate.mustBeProperRange}

    options.Error (1, 1) logical = true
    options.Warning (1, 1) logical = true
end
%)
% >=R2019b


% <=R2019a
%{
function [flag, listMissing, listSuspect] = checkInitials(this, inputDb, range, varargin)

persistent pp
if isempty(pp)
    pp = extend.InputParser("Model/checkInitials");
    addRequired(pp, 'model', @(x) isa(x, 'Model'));
    addRequired(pp, 'inputDb', @validate.databank);
    addRequired(pp, 'range', @validate.properRange);
    addParameter(pp, 'Error', true, @validate.logicalScalar);
    addParameter(pp, 'Warning', true, @validate.logicalScalar);
end
parse(pp, this, inputDb, range, varargin{:});
%}
% <=R2019a


messageFunc = @(varargin) [];
if options.Error
    messageFunc = @exception.error;
elseif options.Warning
    messageFunc = @exception.warning;
end
logStyle = "none";

flag = true;
range = double(range);
startDate = range(1);

idInit = reshape(getIdInitialConditions(this), 1, []);
names = reshape(string(this.Quantity.Name), 1, []);

numAlt = nan(size(idInit));
inxValid = true(size(idInit));
for i = 1 : numel(idInit)
    pos = real(idInit(i));
    sh = imag(idInit(i));
    if ~isfield(inputDb, names(pos));
        inxValid(i) = false;
        continue
    end
    field = inputDb.(names(pos));
    if ~isa(field, 'NumericTimeSubscriptable')
        inxValid(i) = false;
        continue
    end
    value = getDataFromTo(field, dater.plus(startDate, sh));
    numAlt(i) = numel(value);
    if ~all(isfinite(value))
        inxValid(i) = false;
    end
end

listMissing = string.empty(1, 0);
if any(~inxValid)
    flag = false;
    listMissing = printSolutionVector(this, idInit(~inxValid), logStyle);
    listMissing = reshape(string(listMissing), 1, []);
    messageFunc([
        "Model:MissingInitial"
        "This initial condition is missing from input data: %s"
    ], listMissing);
end

testNumAlt = numAlt;
inxSuspect = ~isnan(testNumAlt) & testNumAlt~=1;
listSuspect = string.empty(1, 0);
if numel(unique(testNumAlt(~inxSuspect)))>1
    flag = false;
    listSuspect = printSolutionVector(this, idInit(inxSuspect), logStyle);
    listSuspect = reshape(string(listSuspect), 1, []);
    messageFunc([
        "Model:InvalidSizeInitial"
        "Some initial conditions in the input data have inconsistent size; "
        "suspect some of the following: %s"
    ], join(listSuspect, " "));
end

end%

