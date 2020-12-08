function out = interleaver(in, n_bpscs, n_cbps, ppdu_fmt, n_chan)
%INTERLEAVER Bit interleaver
%
%   Authors: Ioannis Sarris, Sebastian Schiessl, u-blox
%   contact email: ioannis.sarris@u-blox.com
%   August 2018; Last revision: 04-December-2020

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
n_col = 16;
n_row = n_cbps/16;
if (ppdu_fmt == 2)
    % Interleaver has the same effect as the LDPC tone mapper
    % Note: LDPC tone mapper might be removed from 802.11bd
    % TODO: verify if this is still necessary
    if (n_chan == 1)
        n_col = 13;
        n_row = 4*n_bpscs; % D_TM = 4
    elseif (n_chan == 2)
        n_col = 18;
        n_row = 6*n_bpscs; % D_TM = 6
    else
        error('n_chan not supported')
    end
end

% s-parameter
s = max(n_bpscs/2, 1);

% Initialize output
out = zeros(n_cbps, 1);

% Input index
kk = (0:n_cbps - 1);

% First permutation
ii = n_row*mod(kk, n_col) + floor(kk/n_col);

% Second permutation
jj = s*floor(ii/s) + mod(ii + n_cbps - floor(n_col*ii/n_cbps), s);

% Interleaver mapping
out(jj + 1) = in(kk + 1);

end
