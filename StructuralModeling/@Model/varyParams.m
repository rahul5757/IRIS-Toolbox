% varyParams  Create array of user-supplied time-varying values for regular parameters
%
% -[IrisToolbox] for Macroeconomic Modeling
% -Copyright (c) 2007-2021 [IrisToolbox] Solutions Team

function overrideParams = varyParams(this, baseRange, override)

inxP = getIndexByType(this.Quantity, 4);
requiredNames = string.empty(1, 0);
optionalNames = this.Quantity.Name(inxP);

if isempty(intersect(fieldnames(override), optionalNames))
    overrideParams = [ ];
    return
end

allowedNumeric = @all;
allowedLog = string.empty(1, 0);
context = "";
dbInfo = checkInputDatabank( ...
    this, override, baseRange ...
    , requiredNames, optionalNames ...
    , allowedNumeric, allowedLog ...
    , context ...
);

overrideParams = requestData( ...
    this, dbInfo, override ...
    , [requiredNames, optionalNames], baseRange ...
);

overrideParams = numeric.removeTrailingNaNs(overrideParams, 2);

end%
