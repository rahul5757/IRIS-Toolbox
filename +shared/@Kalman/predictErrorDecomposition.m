% predictErrorDecomposition  Prediction error decomposition and objective function evaluation
%
% -[IrisToolbox] for Macroeconomic Modeling
% -Copyright (c) 2007-2021 [IrisToolbox] Solutions Team

function [obj, s] = predictErrorDecomposition(s, opt)

numY = s.NumY;
numF = s.NumF;
numB = s.NumB;
numE = s.NumE;
numG = s.NumG;
numExtdPeriods = s.NumExtdPeriods;

numOutlik = s.NumOutlik; % Number of dtrend params concentrated out of lik function
numEstimInit = s.NumEstimInit; % Number of init conditions estimated as fixed unknowns

y1 = s.y1;
Ta = s.Ta(:, :, min(2, end));
ka = s.ka;
jy = false(numY, 1);
X = s.X;
needsTransform = ~isempty(s.U);

K0 = zeros(numB, 0);
K1 = zeros(numB, 0);
pe = zeros(0, 1);
ZP = zeros(0, numB);

% Objective function or its contributions
obj = NaN;
if opt.ObjFuncContributions
    obj = nan(1, numExtdPeriods);
end

% Initialise objective function components
peFipe = zeros(1, numExtdPeriods);
logdetF = zeros(1, numExtdPeriods);

% Effect of outofliks and fixed init states on a(t)
Q1 = zeros(numB, numOutlik);
Q2 = eye(numB, numEstimInit);
% Effect of outofliks and fixed init states on pe(t)
M1 = zeros(0, numOutlik);
M2 = zeros(0, numEstimInit);

% Initialise flags
isPout = numOutlik>0;
isInit = numEstimInit>0;
isEst = isPout || isInit;

% Initialize sum terms used in out-of-lik estimation.
MtFiM = zeros(numOutlik+numEstimInit, numOutlik+numEstimInit, numExtdPeriods);
MtFipe = zeros(numOutlik+numEstimInit, numExtdPeriods);


%
% Initial Condition
%-------------------
%
a = s.InitMean;
PReg = s.InitMseReg;
PInf = s.InitMseInf;
P = PReg;
if ~isempty(PInf) && any(diag(PInf)>0)
    P = P + PInf;
end


% Initialize matrices that are to be stored.
if ~s.IsObjOnly

    % `pe` is allocated as an numY-by-1-by-numExtdPeriods array because we re-use the same
    % algorithm for both regular runs of the filter and the contributions.
    s.pe = nan(numY, 1, numExtdPeriods);

    s.F = nan(numY, numY, numExtdPeriods);
    s.FF = nan(numY, numY, numExtdPeriods);
    s.Fd = nan(1, numExtdPeriods);
    s.M = nan(numY, numOutlik+numEstimInit, numExtdPeriods);

    if s.storePredict
        % `a0`, `y0`, `ydelta` are allocated as an numY-by-1-by-numExtdPeriods array because we
        % re-use the same algorithm for both regular runs of the filter and the
        % contributions.
        s.a0 = nan(numB, 1, numExtdPeriods);
        s.a0(:, 1, 1) = s.InitMean;
        s.y0 = nan(numY, 1, numExtdPeriods);
        s.ydelta = zeros(numY, 1, numExtdPeriods);
        s.f0 = nan(numF, 1, numExtdPeriods);

        s.Pa0 = nan(numB, numB, numExtdPeriods);
        s.Pa1 = nan(numB, numB, numExtdPeriods);
        s.Pa0(:, :, 1) = P;
        s.Pa1(:, :, 1) = P;
        s.De0 = nan(numE, numExtdPeriods);

        % Kalman gain matrices
        s.K0 = nan(numB, numY, numExtdPeriods);
        s.K1 = nan(numB, numY, numExtdPeriods);

        %s.Q = zeros(numB, numOutlik+numEstimInit, numExtdPeriods);
        %s.Q(:, numOutlik+1:end, 1) = Q2;
        s.Q = cell(1, numExtdPeriods);
        s.Q{1} = [Q1, Q2];
        if s.retSmooth
            s.L = nan(numB, numB, numExtdPeriods);
            %
            % `L(1) = Ta(2<-1)`
            %
            s.L(:, :, 1) = Ta;
        end
    end
    if s.retPredStd || s.retFilterStd || s.retSmoothStd || s.retFilterMse || s.retSmoothMse
        s.Pb0 = nan(numB, numB, numExtdPeriods);
        s.Dy0 = nan(numY, numExtdPeriods);
        s.Db0 = nan(numB, numExtdPeriods);
    end
    if s.retCont
        s.MtFi = nan(numOutlik+numEstimInit, numY, numExtdPeriods);
    end
end

% Number of actually observed data points
numObs = zeros(1, numExtdPeriods);

status = 'ok';

if s.NeedsSimulate
    [simulateFunc, simulateFirstOrderFunc, rect, data, blazer] = s.Simulate{:};
    rect.SimulateY = true;
    rect.UpdateEntireXib = true;
end



%=========================================================================
for t = 2 : numExtdPeriods
    %
    % Start with `Ta(t<-t-1)` here
    %

    %
    % Effect of out-of-liks on `a(t)`
    %---------------------------------
    %
    % Effect of outofliks on `a(t)`; this step must be made before
    % updating `jy` because we use `Ta(t<-t-1)` and `K0(t<-t-1)`
    if isPout
        Q1 = Ta*Q1 - K0*M1(jy, :);
    end

    % Effect of fixed init states on `a(t)`; this step must be made
    % before updating `jy` because we use `Ta(t<-t-1)` and `K0(t<-t-1)`
    if isInit
        Q2 = Ta*Q2 - K0*M2(jy, :);
    end

    %
    % Prediction step t|t-1 for the alpha vector
    %--------------------------------------------
    %
    % Mean prediction `a(t|t-1)`.
    if ~s.NeedsSimulate
        % Prediction `a(t|t-1)` based on `a(t-1|t-2)`, prediction error `pe(t-1)`,
        % the transition matrix `Ta(t-1)`, and the Kalman gain `K0(t-1)`.
        %
        % `a(t|t-1) = Ta(t<-t-1)*a(t-1|t-1)` ==>
        % `a(t|t-1) = Ta(t<-t-1)*[ a(t-1|t-2) + K1(t-1)*pe(t-1) ]` ==>
        % `a(t|t-1) = Ta(t<-t-1)*a(t-1|t-2) + K0(t<-t-1)*pe(t-1)`
        % where `K0(t<-t-1) = Ta(t<-t-1)*K1(t-1)`
        %
        a = Ta*a + K0*pe;

        % Adjust the prediction step for the constant vector
        if ~isempty(ka)
            a = a + ka(:, min(t, end));
        end
    else
        % Run non-linear simulation to produce the mean prediction.
        init = a + K1*pe;
        [a, f0, simulatedY] = hereSimulatePredict(init);
        s.f0(:, 1, t) = f0;
    end

    %
    % Reduced-form covariance matrices at time t
    %
    Omg = s.Omg(:, :, min(t, end));
    Sa = s.Sa(:, :, min(t, end));
    Sy = s.Sy(:, :, min(t, end));


    %
    % MSE P(t|t-1) based on P(t-1|t-2), the predictive Kalman gain `K0(t-1)`, and
    % and the reduced-form covariance matrix Sa(t). Make sure P is numerically
    % symmetric and does not explode over time.
    %
    % `P(t|t-1) = [ Ta(t<-t-1)*P(t-1|t-2) - K0(t<-t-1)*Z(t-1)*P(t-1|t-2) ]*Ta(t<-t-1) + Sa(t<-t-1)`
    %
    P = (Ta*P - K0*ZP)*Ta' + Sa;
    P = (P + P')/2;


    %
    % Prediction step t|t-1 for measurement variables
    %
    % Index of observations available at time t, `jy`, and index of
    % conditioning observables available at time t, `cy`.
    jy = s.yindex(:, t);
    if isempty(opt.Condition)
        cy = false(numY, 1);
        isCondition = false;
    else
        cy = jy & opt.Condition(:);
        isCondition = any(cy);
    end

    % Z matrix at time t
    Z = s.Z(:, :, min(t, end));
    Zj = Z(jy, :);

    ZP = Zj*P;
    PZt = ZP';

    % Mean prediction for observables available, y0(t|t-1)
    if ~isempty(s.d)
        d = s.d(:, min(t, end));
    end
    if ~s.NeedsSimulate
        y0 = Zj*a;
        if ~isempty(s.d)
            y0 = y0 + d(jy, 1);
        end
    else
        y0 = simulatedY(jy, 1);
    end

    % Prediction MSE, `F(t|t-1)`, for observables available at time t; the
    % number of rows in `F(t|t-1)` changes over time
    Fj = Zj*PZt + Sy(jy, jy);

    % Prediction errors for the observables available, `pe(t)`; the number
    % of rows in `pe(t)` changes over time
    pe = y1(jy, t) - y0;

    if opt.CheckFmse
        % Only evaluate the cond number if the test is requested by the user
        condNumber = rcond(Fj);
        if condNumber<opt.FmseCondTol || isnan(condNumber)
            status = 'condNumberFailed';
            break
        end
    end

    %
    % Kalman gain in contemporaneous filtering
    %
    lastwarn('');
    K1 = PZt/Fj;

    %
    % Effect of out-of-liks on `-pe(t)`
    %
    if isEst
        M1 = Z*Q1 + X(:, :, t);
        M2 = Z*Q2;
        M = [M1, M2];
    end

    %
    % Update to `Ta(t+1<-t)` here
    %
    Ta = s.Ta(:, :, min(t+1, end));

    %
    % Kalman gain in next prediction step
    %
    % `K0(t+1<-t) = Ta(t+1<-t)*K1(t)`
    %
    if t<numExtdPeriods
        K0 = Ta*K1;
    else
        K0 = NaN;
    end

    %
    % Objective Function Components
    %-------------------------------
    %
    if s.InxObjFunc(t)
        % The following variables may change in `doCond`, but we need to store the
        % original values in `doStorePed`.
        pex = pe;
        Fx = Fj;
        xy = jy;
        if isEst
            Mx = M(xy, :);
        end

        if isCondition
            % Condition the prediction step
            hereCondition( );
        end

        if isEst
            if opt.ObjFunc==1
                MtFi = Mx'/Fx;
            elseif opt.ObjFunc==2
                W = opt.Weighting(xy, xy);
                MtFi = Mx'*W;
            else
                MtFi = 0;
            end
            MtFipe(:, t) = MtFi*pex;
            MtFiM(:, :, t) = MtFi*Mx;
        end

        % Compute components of the objective function if this period is included
        % in the user specified objective range
        numObs(1, t) = nnz(xy);
        if opt.ObjFunc==1
            % Likelihood function
            peFipe(1, t) = (pex.'/Fx)*pex;
            logdetF(1, t) = log(det(Fx));
        elseif opt.ObjFunc==2
            % Weighted sum of prediction errors
            W = opt.Weighting(xy, xy);
            peFipe(1, t) = pex.'*W*pex;
        end
    end

    if ~s.IsObjOnly
        % Store prediction error decomposition
        hereStorePed( );
    end

end
%=========================================================================



switch status
    case 'condNumberFailed'
        obj(1) = s.OBJ_FUNC_PENALTY;
        V = 1;
        est = nan(numOutlik+numEstimInit, 1);
        Pest = nan(numOutlik+numEstimInit);
    otherwise % status=='ok'
        % Evaluate common variance scalar, out-of-lik parameters, fixed init
        % conditions, and concentrated likelihood function.
        [obj, V, est, Pest] = kalman.oolik(logdetF, peFipe, MtFiM, MtFipe, numObs, opt);
end


%
% Store estimates of out-of-lik parameters, `delta`, cov matrix of
% estimates of out-of-lik parameters, `Pdelta`, fixed init conditions,
% `init`, and common variance scalar, `V`.
%
s.delta = est(1:numOutlik, :);
s.PDelta = Pest(1:numOutlik, 1:numOutlik);
s.init = est(numOutlik+1:end, :);
s.V = V;

if ~s.IsObjOnly && s.retCont
    if isEst
        s.sumMtFiM = sum(MtFiM, 3);
    else
        s.sumMtFiM = [ ];
    end
end

return


    function hereStorePed( )
        % hereStorePed  Store predicition error decomposition
        s.F(jy, jy, t) = Fj;
        s.pe(jy, 1, t) = pe;
        if isEst
            s.M(:, :, t) = M;
        end
        if s.storePredict
            hereStorePredict( );
        end
    end%




    function hereStorePredict( )
        % hereStorePredict  Store prediction and updating steps
        s.a0(:, 1, t) = a;
        s.Pa0(:, :, t) = P;
        s.Pa1(:, :, t) = P - K1*ZP;
        s.De0(:, t) = diag(Omg);
        % Compute mean and MSE for all measurement variables, not only
        % for the currently observed ones when predict data are returned
        if ~s.NeedsSimulate
            s.y0(:, 1, t) = Z*a;
            if ~isempty(s.d)
                s.y0(:, 1, t) = s.y0(:, 1, t) + d;
            end
        else
            s.y0(:, 1, t) = simulatedY;
        end
        s.F(:, :, t) = Z*P*Z' + Sy;
        s.FF(jy, jy, t) = Fj;
        s.K1(:, jy, t) = K1;
        %s.Q(:, :, t) = [Q1, Q2];
        s.Q{t} = [Q1, Q2];

        if t<numExtdPeriods
            s.K0(:, jy, t) = K0;
            if s.retSmooth
                %
                % `L(t) = Ta(t+1<-t) - K0(t+1<-t)*Z(t)`
                %
                s.L(:, :, t) = Ta - K0*Zj;
            end
        end

        if s.retPredStd || s.retFilterStd || s.retSmoothStd || s.retFilterMse || s.retSmoothMse
            if needsTransform
                U = s.U(:, :, min(t, end));
                s.Pb0(:, :, t) = kalman.pa2pb(U, P);
            end
            s.Dy0(:, t) = diag(s.F(:, :, t));
            s.Db0(:, t) = diag(s.Pb0(:, :, t));
        end

        if isEst && s.retCont
            s.MtFi(:, xy, t) = MtFi;
        end
    end%




    function [a, f0, y0] = hereSimulatePredict(init)
        data.ForceInit = init;
        if needsTransform
            U = s.U(:, :, min(t, end));
            data.ForceInit = U*data.ForceInit;
        end
        idFrame = 1;
        simulateFunc(simulateFirstOrderFunc, rect, data, blazer, idFrame);
        a = data.YXEPG(rect.LinxOfXib);
        if needsTransform
            a = U\a;
        end
        f0 = data.YXEPG(rect.LinxOfXif);
        y0 = data.YXEPG(rect.LinxY);
    end%




    function hereCondition( )
        % Condition time t predictions upon time t outcomes of conditioning
        % measurement variables
        Zc = Z(cy, :);
        y0c = Zc*a;
        if ~isempty(s.d)
            y0c = y0c + d(cy, 1);
        end
        pec = y1(cy, t) - y0c;
        Fc = Zc*P*Zc.' + Sy(cy, cy);
        Kc = (Zc*P).' / Fc;
        ac = a + Kc*pec;
        Pc = P - Kc*Zc*P;
        Pc = (Pc + Pc')/2;
        % Index of available non-conditioning observations
        xy = jy & ~cy;
        if any(xy)
            Zx = Z(xy, :);
            y0x = Zx*ac;
            if ~isempty(s.d)
                y0x = y0x + d(xy, 1);
            end
            pex = y1(xy, t) - y0x;
            Fx = Zx*Pc*Zx.' + Sy(xy, xy);
            if isEst
                ZZ = Zx - Zx*Kc*Zc;
                M1x = ZZ*Q1 + X(xy, :, t);
                M2x = ZZ*Q2;
                Mx = [M1x, M2x];
            end
        else
            pex = double.empty(0, 1);
            Fx = double.empty(0);
            if isEst
                Mx = double.empty(0, numOutlik+numEstimInit);
            end
        end
    end%
end%

