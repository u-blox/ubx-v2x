function out = interleaver(in, n_bpscs, n_cbps)
%INTERLEAVER Bit interleaver
%
%   Author: Ioannis Sarris, u-blox
%   email: ioannis.sarris@u-blox.com
%   August 2018; Last revision: 30-August-2018

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

% Interleaver configuration
n_row = n_cbps/16;

% s-parameter
s = max(n_bpscs/2, 1);

% Initialize output
out = zeros(n_cbps, 1);

% Input index
kk = (0:n_cbps - 1);

% First permutation
ii = n_row*mod(kk, 16) + floor(kk/16);

% Second permutation
jj = s*floor(ii/s) + mod(ii + n_cbps - floor(16*ii/n_cbps), s);

% Interleaver mapping
out(jj + 1) = in(kk + 1);

end
