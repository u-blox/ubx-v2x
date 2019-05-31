%BATCH_SIM - Batch simulation script
%   Top-level simulation script looping over MCS, SNR and Monte-Carlo iterations
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

%% Initialization
clc
clear all
close all

addpath('./functions;./mex')

% Set random number generator to specific seed
rand_stream = RandStream('mt19937ar', 'Seed', 0);
RandStream.setGlobalStream(rand_stream);

%% Simulation Parameters
% Simulation parameters
SIM.snr             = 20;       % SNR value (dB)
SIM.use_mex         = true;    % Use MEX functions to accelerate simulation
SIM.apply_cfo       = true;     % Apply CFO impairment on Tx and Rx

% Transmitter parameters
TX.mcs              = 2;        % Modulation and coding scheme value
TX.payload_len      = 300;      % PHY payload length (bytes)
TX.window_en        = false;    % Apply time-domain windowing
TX.w_beta           = 3;        % Kaiser window beta coefficient for spectral shaping (0: disabled)

% Receiver parameters
RX.pdet_thold       = 20;       % Packet detection threshold
RX.t_depth          = 2;        % Channel tracking time depth averaging (OFDM symbols)

tic

% Initialize scrambler with a 7-bit non-allzero PN sequence
TX.pn_seq = logical(de2bi(randi([1 127]), 7, 'left-msb'))';

% Create pseudo-random PSDU binary message (account for CRC-32)
tmp_msg = randi([0 255], TX.payload_len - 4, 1)';

% Create MAC payload by adding CRC-32 on random data
TX.mac_payload = crc32(tmp_msg);

% Transmitter + impairments + receiver model (MEX or M)
if SIM.use_mex
    [tx_wf, data_f_mtx, data_msg, PHY] = sim_tx_mex(TX.mcs, TX.mac_payload, TX.pn_seq, TX.window_en, TX.w_beta);
    [rx_wf, s0_len] = add_impairments_mex(SIM, tx_wf);
    [pld_bytes, err] = sim_rx_mex(rx_wf, s0_len, data_f_mtx, RX.t_depth, RX.pdet_thold);
else
    [tx_wf, data_f_mtx, data_msg, PHY] = sim_tx(TX.mcs, TX.mac_payload, TX.pn_seq, TX.window_en, TX.w_beta);
    [rx_wf, s0_len] = add_impairments(SIM, tx_wf);
    [pld_bytes, err] = sim_rx(rx_wf, s0_len, data_f_mtx, RX.t_depth, RX.pdet_thold);
end

% Display debugging information
switch err
    case 0
        fprintf('.'); % No error
    case 1
        fprintf('x'); % Packet detection error
    case 2
        fprintf('o'); % SIG error
    case 3
        fprintf('!'); % DATA error
end

toc
