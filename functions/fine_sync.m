function [f_idx, f_cfo] = fine_sync(in, c_idx, n_chan)
%FINE_SYNC Fine synchronization
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

% Obtain original LTF waveform
ltf_wf = ltf_tx(0, n_chan);

% Input LTF signal
i_rx = 1;
offset = 160*n_chan; % number of samples in L-STF
xc_in = in((0:64*n_chan - 1) + c_idx + offset, i_rx);

% Cross-correlation of input with reference signals
xc = abs(xcorr(ltf_wf(32*n_chan+1:96*n_chan), xc_in));

% Find the maximum value
[~, tmp] = max(xc);

% Adjust index
if n_chan == 1
    % should be 285 for AWGN and s0_len==100
    % 285 = 1+100+160+24, i.e., discard the first 24 symbols of the length 32 CP of the LTF
    f_idx = 216 - tmp + c_idx;
else
    % should be 469 for AWGN and s0_len==100
    % 469 = 1+100+320+48, i.e., discard the first 48 symbols of the length 64 CP of the LTF
    f_idx = 432 - tmp + c_idx ;
end

% Fine CFO estimation
if (n_chan == 1)
    r1 = in(f_idx:(f_idx + 63), 1);
    r2 = in((f_idx + 64):(f_idx + 127), 1);
    f_cfo = -angle(sum(r1.*conj(r2)))/64/2/pi;
elseif (n_chan == 2)
    % TODO: f_cfo estimation for 20 MHz waveforms
    f_cfo = 0;
else
    error('n_chan not supported')
end

end
