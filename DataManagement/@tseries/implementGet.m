% implementGet  Implement get method for tseries objects
%
% Backend [IrisToolbox] method
% No help provided

% -IRIS Macroeconomic Modeling Toolbox
% -Copyright (c) 2007-2021 [IrisToolbox] Solutions Team

function [answ, flag] = implementGet(this, query, varargin)

answ = [ ];
flag = true;

start = double(this.Start);

switch query
    case {'range', 'first2last', 'start2end', 'first:last', 'start:end'}
        answ = reshape(this.Range, 1, [ ]);
        
        
    case {'min', 'minrange', 'nanrange'}
        sample = all(~isnan(this.Data(:, :)), 2);
        answ = this.Range;
        answ = answ(sample);
        
        
    case {'start', 'startdate', 'first'}
        answ = this.Start;
    
        
    case {'nanstart', 'nanstartdate', 'nanfirst', 'allstart', 'allstartdate'}
        if isnan(start) || isempty(this.Data)
            answ = TimeSubscriptable.StartDateWhenEmpty;
        else
            sample = all(~isnan(this.Data(:, :)), 2);
            if isempty(sample) || ~any(sample)
                answ = TimeSubscriptable.StartDateWhenEmpty;
            else
                pos = find(sample, 1, 'first');
                answ = dater.plus(start, pos-1);
            end
        end
        answ = DateWrapper(answ);
        
        
    case {'end', 'enddate', 'last'}
        answ = this.End;
        
        
    case {'nanend', 'nanenddate', 'nanlast', 'allend', 'allenddate'}
        if isnan(start) || isempty(this.Data)
            answ = TimeSubscriptable.StartDateWhenEmpty;
        else
            sample = all(~isnan(this.Data(:, :)), 2);
            if isempty(sample) || ~any(sample)
                answ = TimeSubscriptable.StartDateWhenEmpty;
            else
                pos = find(sample, 1, 'last');
                answ = dater.plus(start, pos-1);
            end
        end
        answ = DateWrapper(answ);
        
        
    case {'freq', 'frequency', 'per', 'periodicity'}
        answ = dater.getFrequency(start);
        answ = Frequency(answ);
    
        
    case {'data', 'value', 'values'}
        % Not documented. Use x.Data directly.
        answ = this.Data;
        
        
    case {'comment', 'comments'}
        % Not documented. User x.Comment directly.
        answ = comment(this);
        
        
    otherwise
        flag = false;
end

end%

