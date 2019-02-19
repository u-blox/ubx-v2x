function [tx_wf, data_f_mtx, data_msg, PHY] = sim_tx(mcs, payload_len, window_en, w_beta)
%SIM_RX High-level transmitter function
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

% Create structure with PHY parameters
[PHY, data_msg] = tx_phy_params(mcs, payload_len);

% Get STF waveform
stf_wf = stf_tx(w_beta);

% Get LTF waveform
ltf_wf = ltf_tx(w_beta);

% Get SIG waveform
sig_wf = sig_tx(PHY, w_beta);

% Calculate number of required pad bits
pad_len = PHY.n_sym*PHY.n_dbps - (16 + 8*PHY.length + 6);

% Add service and zero-padding (pad + tail)
padding_out = [false(16, 1); data_msg; false(pad_len + 6, 1)];

% Generate data waveform
[data_wf, data_f_mtx] = data_tx(PHY, pad_len, padding_out, w_beta);

% Concatenate output waveform
tx_wf = [stf_wf; ltf_wf; sig_wf; data_wf];

% Apply time-domain windowing
tx_wf = apply_time_window(tx_wf, window_en);

end
