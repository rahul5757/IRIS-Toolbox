% autoswaps  Inquire about or assign autoswap pairs
%{
% ## Syntax for Inquiring About Autoswap Pairs ##
%
%     a = autoswaps(model)
%
%
% ## Syntax for Assigning Autoswap Pairs ##
%
%     model = autoswaps(model, a)
%
%
% ## Input Arguments ##
%
% **`model`** [ Model ] -
% Model object that will be inquired about autoswap pairs or assigned new
% autoswap pairs.
%
% **`a`** [ AutoswapStruct ] -
% AutoswapStruct object containing two substructs, `.Simulate` and
% `.Steady`. Each field in the substructs defines a variable/shock pair (in
% `.Simulate`), or a variable/parameter pair (in `.Steady`).
%
%
% ## Output Arguments ##
%
% **`model`** [ Model ] -
% Model object with the definitions of autoswap pairs newly assigned.
%
% **`a`** [ AutoswapStruct ] -
% AutoswapStruct object containing two substructs, `.Simulate` and
% `.Steady`. Each field in the substructs defines a variable/shock pair (in
% `.Simulate`), or a variable/parameter pair (in `.Steady`).
%
%
% ## Description ##
%
%
% ## Example ##
%
%}

% -[IrisToolbox] for Macroeconomic Modeling
% -Copyright (c) 2007-2021 [IrisToolbox] Solutions Team

function varargout = autoswaps(this, varargin)

if isempty(varargin)
    % ## Get Autoswap Structure ##
    auto = model.component.AutoswapStruct( );
    [~, ~, auto.Simulate] = model.component.Pairing.getAutoswaps(this.Pairing.Autoswaps.Simulate, this.Quantity);
    [~, ~, auto.Steady] = model.component.Pairing.getAutoswaps(this.Pairing.Autoswaps.Steady, this.Quantity);
    varargout{1} = auto;

else
    % ## Set Autoswap Structure ##
    auto = varargin{1};

    % Legacy structure
    if ~isfield(auto, 'Simulate') && isfield(auto, 'dynamic')
        auto.Simulate = auto.dynamic;
    end
    if ~isfield(auto, 'Steady') && isfield(auto, 'steady')
        auto.Steady = auto.steady;
    end
    if isfield(auto, 'Simulate') 
        p = this.Pairing.Autoswaps.Simulate;
        locallySetType(auto.Simulate, p, 'Simulate');
        this.Pairing.Autoswaps.Simulate = p;
    end
    if isfield(auto, 'Steady')
        p = this.Pairing.Autoswaps.Steady;
        locallySetType(auto.Steady, p, 'Steady');
        this.Pairing.Autoswaps.Steady = p;
    end
    varargout{1} = this;

end

return

    function p = locallySetType(auto, p, type)
            namesExogenized = fieldnames(auto);
            namesExogenized = transpose(namesExogenized(:));
            namesEndogenized = struct2cell(auto);
            namesEndogenized = transpose(namesEndogenized(:));
            p = model.component.Pairing.setAutoswaps( ...
                p, type, this.Quantity ...
                , namesExogenized, namesEndogenized ...
            );
    end%
end%

