function [idx, c_cfo, err] = pdet(in, s0_len, pdet_thold)
%PDET Detects start of packet
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

% Obtain original STF waveform
stf_wf = stf_tx(0);

% Input STF signal
xc_in = in(1:(s0_len + 80));

% X-correlation of received waveform with known STF
xc = xcorr(stf_wf(1:64), xc_in);
xc_crop = abs(xc(s0_len + 80 + 63:-1:1));

% Find first occurence of value above threshold
idx = find((xc_crop > pdet_thold), 1, 'first');

% Check if index is valid, else declare packet error
if (isempty(idx) || (idx(1) < s0_len))
    c_cfo = [];
    idx = 0;
    err = true;
    return
else
    idx = idx(1);
    err = false;
end

% Coarse CFO estimation
r1 = in(idx:(idx + 15), 1);
r2 = in((idx + 16):(idx + 31), 1);
c_cfo = -angle(sum(r1.*conj(r2)))/16/2/pi;

end
