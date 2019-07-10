function out = deinterleaver(in, n_bpscs, n_cbps, ppdu_fmt)
%DEINTERLEAVER Bit deinterleaver
%
%   Author: Ioannis Sarris, u-blox
%   email: ioannis.sarris@u-blox.com
%   August 2018; Last revision: 10-July-2019

% Copyright (C) u-blox
%
% All rights reserved.
%
% Permission to use, copy, modify, and distribute this software for any
% purpose without fee is hereby granted, provided that this entire notice
% is included in all copies of any software which is or includes a copy
% or modification of this software and in all copies of the supporting
% documentation for such software.
%
% THIS SOFTWARE IS BEING PROVIDED "AS IS", WITHOUT ANY EXPRESS OR IMPLIED
% WARRANTY. IN PARTICULAR, NEITHER THE AUTHOR NOR U-BLOX MAKES ANY
% REPRESENTATION OR WARRANTY OF ANY KIND CONCERNING THE MERCHANTABILITY
% OF THIS SOFTWARE OR ITS FITNESS FOR ANY PARTICULAR PURPOSE.
%
% Project: ubx-v2x
% Purpose: V2X baseband simulation model

% De-interleaver configuration
n_col = 16;
n_row = n_cbps/16;
if (ppdu_fmt == 2)
    n_col = 13;
    n_row = 4*n_bpscs;
end

% s-parameter
s = max(n_bpscs/2, 1);

% Initialize output
out = zeros(1, numel(in));

% Input index
kk = (0:n_cbps - 1);

% First permutation
ii = n_row*mod(kk, n_col) + floor(kk/n_col);

% Second permutation
jj = s*floor(ii/s) + mod(ii + n_cbps - floor(n_col*ii/n_cbps), s);

% Deinterleaver mapping
out(kk + 1) = in(jj + 1);

end
