% Type `web +databank/clip.md` for help on this function
%
% -IRIS Macroeconomic Modeling Toolbox
% -Copyright (c) 2007-2021 IRIS Solutions Team

% >=R2019b
%(
function outputDb = clip(inputDb, newStart, newEnd, opt)

arguments
    inputDb (1, 1) {validate.mustBeDatabank(inputDb)}
    newStart {mustBeNonempty, validate.mustBeDate(newStart)}
    newEnd {validate.mustBeScalarOrEmpty, validate.mustBeDate(newEnd)} = []

    opt.SourceNames {locallyValidateNames(opt.SourceNames)} = @all
    opt.TargetDb {locallyValidateDb(opt.TargetDb)} = @auto
end
%)
% >=R2019b


% <=R2019a
%{
function outputDb = clip(inputDb, newStart, varargin)

persistent pp
if isempty(pp)
    pp = extend.InputParser('databank.clip');
    addRequired(pp, 'inputDatabank', @validate.databank);
    addRequired(pp, 'newStart', @(x) isequal(x, -Inf) || validate.date(x));
    addOptional(pp, 'newEnd', [], @(x) isempty(x) || isequal(x, Inf) || validate.date(x));

    addParameter(pp, "SourceNames", @all, @(x) isequal(x, @all) || isstring(x) || ischar(x) || iscellstr(x));
    addParameter(pp, "TargetDb", @auto, @(x) isequal(x, @auto) || validate.databank(x));
end
opt = parse(pp, inputDb, newStart, varargin{:});
newEnd = pp.Results.newEnd;
%}
% <=R2019a


newStart = double(newStart);
newEnd = double(newEnd);
if isempty(newEnd)
    newEnd = newStart(end);
end

if isequal(opt.TargetDb, @auto)
    outputDb = inputDb;
end

isNewStartInf = isequal(newStart, -Inf);
isNewEndInf = isequal(newEnd, Inf);

if isNewStartInf && isNewEndInf
    return
end

if ~isNewStartInf
    freq = dater.getFrequency(newStart(1));
else
    freq = dater.getFrequency(newEnd);
end

if isequal(opt.SourceNames, @all)
    list = keys(inputDb);
else
    list = reshape(string(opt.SourceNames), 1, []);
end

for n = list
    if ~isfield(inputDb, n)
        continue
    end
    if isa(inputDb, 'Dictionary')
        field__ = retrieve(inputDb, n);
    else
        field__ = inputDb.(n);
    end
    if isa(field__, 'TimeSubscriptable')
        if isequaln(freq, NaN) || getFrequencyAsNumeric(field__)==freq
            field__ = clip(field__, newStart, newEnd);
        end
    elseif validate.databank(field__)
        field__ = databank.clip(field__, newStart, newEnd, opt);
    end
    if isa(outputDb, 'Dictionary')
        store(outputDb, n, field__);
    else
        outputDb.(n) = field__;
    end
end

end%

%
% Local Functions
%

function locallyValidateNames(input)
    if isa(input, 'function_handle') || validate.list(input)
        return
    end
    error("Validation:Failed", "Input value must be a string array");
end%


function locallyValidateDb(input)
    if isa(input, 'function_handle') || validate.databank(input)
        return
    end
    error("Validation:Failed", "Input value must be a struct or a Dictionary");
end%

