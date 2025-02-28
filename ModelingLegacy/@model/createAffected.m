function this = createAffected(this)
% createAffected  Create logical array of equations affected by changes in parameters and steady-state values
%
% Backend IRIS function
% No help provided

% -IRIS Macroeconomic Modeling Toolbox
% -Copyright (c) 2007-2021 IRIS Solutions Team

numEquations = length(this.Equation);
numQuantities = length(this.Quantity);
minShift = this.Incidence.Dynamic.Shift(1) + 1;
maxShift = this.Incidence.Dynamic.Shift(end) - 1;
indexMT = this.Equation.Type==1 | this.Equation.Type==2;

steadyRef = model.component.Incidence(numEquations, numQuantities, minShift, maxShift);
steadyRef = fill(steadyRef, this.Quantity, this.Equation.Dynamic, indexMT, 'L');

this.Affected = across(this.Incidence.Dynamic, 'Shifts') | across(steadyRef, 'Shifts');

end
