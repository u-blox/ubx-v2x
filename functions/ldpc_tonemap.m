function sym_out = ldpc_tonemap(sym_in, n_fft)
%LDPC_TONEMAP Applies LDPC tone-mapping
%
%   Author: Ioannis Sarris, u-blox
%   email: ioannis.sarris@u-blox.com
%   July 2019; Last revision: 10-July-2019

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

% Tone mapping configuration per bandwidth
switch n_fft
    case 64
        d_tm = 4;
        n_sd = 52;
    case 128
        d_tm = 6;
        n_sd = 108;
end

% Input index
idx_in = 0:n_sd - 1;

% Output index
idx_out = d_tm.*mod(idx_in, n_sd/d_tm) + floor(idx_in*d_tm/n_sd);

% Interleave symbols
sym_out = sym_in;
sym_out(idx_out + 1, :, :) = sym_in(idx_in + 1, :, :);

end