function [yhat, p, pCI] = logregPredictBayes(model, X, method)
% Approximate p(i) = p(y=1|X(i,i), model) and yhat(i) = ind{p(i) > 0.5}
% Method should be one of
% - 'plugin': uses p(y=1 | X(i,:), E[w])
% - 'moderated': uses the Mackay trick to approximate int_w Gauss(w)*sigmoid(y|w)
% - 'vb': uses variational bayes to approximate int_w Gauss(w)*sigmoid(y|w)
% - 'mc': draws Monte Carlo samples from p(w). In this case
%   p(i) = median{p(y=1)}. We also return 
%    pCI(i, :) = [Q5 Q95] = 5% and 95% quantiles 

if nargin < 3
  if nargout >= 3
    method = 'mc';
  else
    method = 'plugin'; % fastest
  end
end

w = model.wN;
V = model.VN;
    
if isfield(model, 'preproc')
    [X] = preprocessorApplyToTest(model.preproc, X);
end

switch method
  case 'plugin'
    p = sigmoid(X*w);
  case 'moderated'
    p = logregPredictMackay(X, w, V);
  case 'mc'
    [p, pCI] = logregPredictBayesMc(X, w, V);
  case 'vb'
    % This is a wrapper to Jan Drugowitsch's code.
    p = bayes_logit_post(X, model.wN, model.VN, model.invVN);
  otherwise
    error(['unrecognized method ' method])
end

yhat = p > 0.5;  % now in [0 1]
yhat = setSupport(yhat, model.ySupport, [0 1]); 
    
end

function [p, pCI] = logregPredictBayesMc(X, w, V)
Nsamples = 100;
ws = gaussSample(w, V, Nsamples);
N = size(X,1);
pCI = zeros(N, 2); p = zeros(N,1);
for i=1:N
  ps = 1 ./ (1+exp(-X(i,:)*ws')); % ps(s) = p(y=1|x(i,:), ws(s,:)) row vec
  tmp = sort(ps, 'ascend');
  Q5 = tmp(floor(0.05*Nsamples));
  Q50 = tmp(floor(0.50*Nsamples));
  Q95 = tmp(floor(0.95*Nsamples));
  p(i) = Q50;
  pCI(i,:) = [Q5 Q95];
end
end

function p = logregPredictMackay(X, wMAP, C)
% Compute p(i) = p(y=1|X(i,:)) \approx int sigma(y w^T X(i,:)) * gauss(w | wMAP, C) dw
% Bishop'06 p219
mu = X*wMAP(:);
[N D] = size(X);
%sigma2 = diag(X * C * X');
sigma2 = zeros(1,N);
for i=1:N
  sigma2(i) = X(i,:)*C*X(i,:)';
end
kappa = 1./sqrt(1 + pi.*sigma2./8);
p = sigmoid(kappa .* mu');

end

 