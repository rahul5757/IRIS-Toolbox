function implementDisp(this)
% implementDisp  Implement display method for model objects
%
% Backend IRIS function
% No help provided

% -IRIS Macroeconomic Modeling Toolbox
% -Copyright (c) 2007-2021 IRIS Solutions Team

DISP_INDENT = iris.get('DispIndent');

%--------------------------------------------------------------------------

ccn = getClickableClassName(this);

if isempty(this.EqtnRhs)
    fprintf(DISP_INDENT);
    fprintf('Empty %s Object\n', ccn);
else
    fprintf('%s Object\n', ccn);
end
fprintf(DISP_INDENT);
fprintf('Number of Equations: [%g]\n',length(this.EqtnRhs));

implementDisp@shared.CommentContainer(this);
implementDisp@shared.UserDataContainer(this);
implementDisp(this.Export);

end%

