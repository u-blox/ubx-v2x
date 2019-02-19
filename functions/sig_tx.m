function [sig_wf, sig_mod] = sig_tx(PHY, w_beta)
%SIG_TX SIG message transmitter/parser
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

% Store this as a persistent variable to avoid reinitialization
persistent bcc_obj

% Initialize BCC encoder object for SIG
if isempty(bcc_obj)
    bcc_obj = comm.ConvolutionalEncoder( ...
        'TrellisStructure', poly2trellis(7, [133 171]), ...
        'TerminationMethod', 'Terminated');
else
    reset(bcc_obj);
end

% Select datarate binary code according to MCS
switch PHY.mcs
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
        sig_rate = [0 0 0 0];
end

% Report error if length exceeds maximum allowed value
if (PHY.length > 4095), error('Maximum length exceeded'), end

% Convert payload length to binary
binary_length = de2bi(PHY.length, 12, 'right-msb');

% Calculate even parity
sig_parity = mod(sum([sig_rate, binary_length]), 2);

% Form SIG uncoded message
sig_msg = logical([sig_rate, 0, binary_length, sig_parity, 0 0 0 0 0 0].');

% Convolutional encoder
sig_enc = step(bcc_obj, sig_msg);

% Interleaver
sig_int = interleaver(sig_enc(1:48), 1, 48);

% BPSK modulation
sig_mod = 2*sig_int - 1;

% Initialize base f-domain representation
sig_sp = zeros(64, 1);

% Map modulated symbols on data subcarriers
sig_sp(PHY.data_idx) = sig_mod;

% Append pilots
sig_sp(PHY.pilot_idx) = PHY.pilot_val;

% Apply spectral shaping window
sig_sp = sig_sp.*kaiser(64, w_beta);

% Time-domain SIG waveform
sig_wf_base = 1/sqrt(52)*dot11_ifft(sig_sp, 64);

% Append CP
sig_wf = [sig_wf_base(49:64); sig_wf_base];

end
