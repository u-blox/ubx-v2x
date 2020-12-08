function [x_p, x_d_cfo, snr, r_phase_off, llr_in] = sig_pre_rx(r, h_est, data_idx, pilot_idx, n_chan, prev_cfo_corr, new_poff_weight)
%SIG_PRE_RX Get f-domain SIG messages (L-SIG, RL-SIG, NGV-SIG, RNGV-SIG) for preamble autodetection and as input to decoder
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

% Perform FFT & normalization
n_fft = 64*n_chan;
cp_len = 16*n_chan;
ofdm_off = cp_len/2;

y = complex(zeros(n_fft, 1));
% SIG field is only decoded for this RX chain.
% TODO: implement MRC for multiple RX antennas
i_rx = 1;
y(:, i_rx) = dot11_fft(r([cp_len+1:cp_len+n_fft-ofdm_off cp_len-ofdm_off+1:cp_len], i_rx), n_fft)*sqrt(52*n_chan)/n_fft;

% Frequency-domain smoothing
h_est(:,i_rx) = fd_smooth(h_est(:,i_rx), 48);

% Pilot equalization with CFO correction
x_p = y(pilot_idx, i_rx)./h_est(pilot_idx, i_rx).*[1 1 1 -1].'*exp(-1j*prev_cfo_corr);

% Residual CFO estimation
r_phase_off = mean(angle(x_p));

% Overall phase correction
phase_corr = prev_cfo_corr + r_phase_off * new_poff_weight;

% Data equalization
x_d = y(data_idx, i_rx)./h_est(data_idx, i_rx);

% Data CFO correction
x_d_cfo = x_d*exp(-1j* phase_corr );

% SNR input to Viterbi
snr = abs(h_est(data_idx, i_rx));

% LLR demapping
llr_in = llr_demap(x_d_cfo.', 1, snr);

end
