function [idx, c_cfo, err] = pdet(in, s0_len, pdet_thold, n_chan)
%PDET Detects start of packet
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

% Obtain original STF waveform
% In 20 MHz channels, the full (duplicated) 20 MHz waveform is used
% TODO: change algorithm to work also when there is no or a different signal on one of the 10 MHz subchannels
stf_wf = stf_tx(0, n_chan);

% pdet currently only works only for this RX chain/antenna
% TODO: enable RX diversity in pdet
i_rx = 1;

% Input first half of STF signal
% TODO: use the full waveform
xc_in = in(1:(s0_len + 80*n_chan), i_rx);

% X-correlation of received waveform with known STF
xc = xcorr(stf_wf(1:64*n_chan), xc_in);

xc_crop = abs(xc(s0_len + 80*n_chan + 64*n_chan-1:-1:1));

% Find first occurence of value above threshold
idx_vec = find((xc_crop > pdet_thold), 1, 'first');

% Check if index is valid, else declare packet error
if (isempty(idx_vec) || (idx_vec(1) < s0_len))
    c_cfo = [];
    idx = 0;
    err = true;
    return
else
    idx = idx_vec(1);
    err = false;
end
% Coarse CFO estimation
if n_chan == 1
    r1 = in(idx:(idx + 15), 1);
    r2 = in((idx + 16):(idx + 31), 1);
    c_cfo = -angle(sum(r1.*conj(r2)))/16/2/pi;
elseif n_chan == 2
    % TODO: coarse CFO estimation for 20 MHz reception
    c_cfo = 0;
else
    error('n_chan not supported')
end

end
