function G = precmatToAdjmat(Lambda, thresh)
% Convert a precision matrix to an adjacency matrix
if nargin < 2, thresh = 1e-9; end
G = Lambda;
G(abs(G) < thresh) = 0;
G = abs(sign(G));
G = setdiag(G,0);

end