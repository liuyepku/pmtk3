function [model, logev] = logregFitBayes(X, y, varargin)
% Fit logistic regression using Bayesian inference
% X is n*d, y is d*1, can be 0/1 or -1/+1
% Do not add a column of 1s
%
% By default we use a N(0,(1/lambda) I) prior
%
% INPUTS:
% method: one of these
% - 'laplace' use Laplace approximation: must specify 'lambda' (binary only)
% - 'vb' use Variational Bayes (binary only)
% - 'eb' use Empirical Bayes (can be multiclass, uses netlab)
%
% preproc       ... a struct, passed to preprocessorApplyToTtrain
%
% OUTPUT
% model.wN and model.VN contain posterior.
% logev is  the log marginal likelihood

wantLogev = (nargout >= 2);
if wantLogev
  method = 'eb';
else
  method = 'laplace'; % faster
end

[preproc, method, lambda] = process_options(varargin, ...
  'preproc', preprocessorCreate('addOnes', true, 'standardizeX', true), ...
  'method', 'eb', 'lambda', 0);

nclasses = nunique(y);
targets = dummyEncoding(y(:), nclasses);
model.isbinary = nclasses < 3;
[y, ySupport] = setSupport(y, [-1 1]);

if ~strcmpi(method, 'laplace')
  % Laplace calls logregFit which calls ppApply already...
  [model.preproc, X] = preprocessorApplyToTrain(preproc, X);
end

switch method
  case 'laplace'
    [model] = logregFitLaplaceApprox(X, y, lambda, preproc);
  case 'vb'
    [model, logev] = logregFitVb(X, y);
  case 'eb'
    [model, logev] = logregFitEbNetlab(X, y);
  otherwise
    error(['unrecognized method ' method])
end

model.type = 'logregBayes';
model.ySupport = ySupport;

end