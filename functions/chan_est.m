function h_est = chan_est(r, n_chan)
%CHAN_EST Channel estimation algorithm, using LTF preamble
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

% LTF f-domain represenation (including DC-subcarrier & guard bands)
ltf_f10 = [zeros(1,6), 1 1 -1 -1 1 1 -1 1 -1 1 1 1 1 1 1 -1 -1 1 1 -1 1 -1 1 1 1 1 0 ...
    1 -1 -1 1 1 -1 1 -1 1 -1 -1 -1 -1 -1 1 1 -1 -1 1 -1 1 -1 1 1 1 1, zeros(1, 5)].';

% Select LTF configuration for 10 or 20 MHz mode
if (n_chan == 1)
    ltf_f = ltf_f10;
    n_fft = 64;
else
    ltf_f = [ltf_f10; 1j * ltf_f10];
    n_fft = 128;
end

% Channel estimate for all Rx antennas
h_est = complex(zeros(64*n_chan, size(r, 2)));
for i_rx = 1:size(r, 2)
    % Average the two t-domain symbols
    r_avg = (r(1:64*n_chan, i_rx) + r(64*n_chan + 1:128*n_chan, i_rx))/2;
    
    % Specify how many samples were discarded in the end and replaced by samples from cyclic prefix
    ofdm_off = 8*n_chan;
    
    % FFT on the averaged sequence
    y = dot11_fft(r_avg([ofdm_off + 1:n_fft, 1:ofdm_off], 1), n_fft)*sqrt(52*n_chan)/n_fft;

    % Least-Squares channel estimation
    h_est(:, i_rx) = y./ltf_f;
end

end