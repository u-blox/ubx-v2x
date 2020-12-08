function sig_wf = sig_tx(PHY, TX, n_chan)
%SIG_TX SIG message transmitter/parser
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

% Store this as a persistent variable to avoid reinitialization
persistent bcc_obj

w_beta = TX.w_beta;

% Initialize BCC encoder object for SIG
if isempty(bcc_obj)
    bcc_obj = comm.ConvolutionalEncoder( ...
        'TrellisStructure', poly2trellis(7, [133 171]), ...
        'TerminationMethod', 'Terminated');
else
    reset(bcc_obj);
end

% Select datarate binary code according to MCS
if PHY.ppdu_fmt == 1
    lsig_mcs = PHY.mcs;
    lsig_length = PHY.psdu_length;
else
    % NGV: Set legacy MCS to 0. The length field in L-SIG indicates the tranmission time.
    % Receiver will use transmission time to derive actual PHY payload length (== MAC payload + MAC padding).
    lsig_mcs = 0;
    
    time_sym = 8;
    % Duration of the legacy preamble
    time_leg_pre = 40;
    
    % Number of LTF symbols
    n_ngvltf = TX.n_ss;
    
    % Duration of LTF symbols and midambles
    time_training = n_ngvltf * PHY.t_ngvltf;
    time_mid = time_training;
    
    % NGV headers with fixed duration: RL-SIG + NGV-SIG + RNGV-SIG + NGV-STF
    time_ngv_fixed_headers = 8+8+8+8;
    
    % Compute TX time and legacy SIG length field
    tx_time = time_leg_pre + time_ngv_fixed_headers + PHY.n_sym*time_sym + 8*ceil((time_training + PHY.n_mid*time_mid - eps)/8);
    lsig_length = (tx_time - time_leg_pre)/8*3-3;
    if (mod(lsig_length, 3) ~= 0)
        error('Error: L-SIG length must be modulo 3')
    end
end

switch lsig_mcs
    case 0
        sig_rate = [1 1 0 1];
    case 1
        sig_rate = [1 1 1 1];
    case 2
        sig_rate = [0 1 0 1];
    case 3
        sig_rate = [0 1 1 1];
    case 4
        sig_rate = [1 0 0 1];
    case 5
        sig_rate = [1 0 1 1];
    case 6
        sig_rate = [0 0 0 1];
    case 7
        sig_rate = [0 0 1 1];
    otherwise % Needed for code generation
        error('sig_rate not supported')
end

% Report error if length exceeds maximum allowed value
if (lsig_length > 4095), error('Maximum length exceeded'), end

% Convert payload length to binary
binary_length = de2bi(lsig_length, 12, 'right-msb');

% Calculate even parity
sig_parity = mod(sum([sig_rate, binary_length]), 2);

% Form SIG uncoded message
sig_msg = logical([sig_rate, 0, binary_length, sig_parity, 0 0 0 0 0 0].');

% Convolutional encoder
sig_enc = step(bcc_obj, sig_msg);

% Interleaver
sig_int = interleaver(sig_enc(1:48), 1, 48, 1, 1);

% BPSK modulation
sig_mod = 2*sig_int - 1;

% Initialize base f-domain representation
sig_sp = zeros(64, 1);

% Map modulated symbols on data subcarriers
sig_sp(PHY.sig_data_idx) = sig_mod;

% Append pilots
sig_sp(PHY.sig_pilot_idx) = PHY.sig_pilot_val;

% Populate the subcarriers in the upper part of the 20 MHz channel, and perform phase rotation
sig_sp2 = [sig_sp; 1j*sig_sp];

% Apply spectral shaping window
sig_sp_win = sig_sp2(1:64*n_chan).*kaiser(64*n_chan, w_beta);

% Time-domain SIG waveform
sig_wf_base = 1/sqrt(52*n_chan)*dot11_ifft(sig_sp_win, 64*n_chan);

% Append CP
sig_wf = [sig_wf_base(48*n_chan+1:64*n_chan); sig_wf_base];

end
