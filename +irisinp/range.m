classdef range < irisinp.generic
    properties
        ReportName = 'Date Range'
        Value = NaN
        Omitted = @error
        ValidFn = @validate.range
    end
    

    methods
        function this = preprocess(this,~)
            if isequal(this.Value,Inf) || isequal(this.Value,@all)
                this.Value = Inf;
            elseif ~isinf(this.Value(1)) && ~isinf(this.Value(end))
                this.Value = this.Value(1) : this.Value(end);
            end
        end
    end
end
