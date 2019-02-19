function [f_idx, f_cfo] = fine_sync(in, c_idx)
%FINE_SYNC Fine synchronization
%
%   Author: Ioannis Sarris, u-blox
%   email: ioannis.sarris@u-blox.com
%   August 2018; Last revision: 19-February-2019

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

% Obtain original LTF waveform
ltf_wf = ltf_tx(0);

% Input LTF signal
xc_in = in(c_idx + 160:c_idx + 223);

% Cross-correlation of input with reference signals
xc = abs(xcorr(ltf_wf(33:96), xc_in));

% Find the maximum value
[~, tmp] = max(xc);

% Adjust index
f_idx = 216 - tmp + c_idx;

% Fine CFO estimation
r1 = in(f_idx:(f_idx + 63), 1);
r2 = in((f_idx + 64):(f_idx + 127), 1);
f_cfo = -angle(sum(r1.*conj(r2)))/64;

end
