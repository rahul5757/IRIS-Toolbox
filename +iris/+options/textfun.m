function default = textfun( )
% textfun  [Not a public function] Default options for textfun package.
%
% Backend IRIS function.
% No help provided.

% -IRIS Macroeconomic Modeling Toolbox.
% -Copyright (c) 2007-2020 IRIS Solutions Team.

%--------------------------------------------------------------------------

default = struct( );

default.delimlist = { ...
    'delimiter', ', ', @ischar, ...
    'lead', '', @(x) ischar(x) || isnumericscalar(x), ...
    'quote', 'none', @(x) any(strcmpi(x,{'none','single','double'})), ...
    'spaced', true, @islogicalscalar, ...
    'trail', '', @(x) ischar(x) || isnumericscalar(x), ...
    'wrap', Inf, @isnumericscalar, ...
    };

end