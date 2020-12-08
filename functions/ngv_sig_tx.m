function ngv_sig_wf = ngv_sig_tx(PHY, w_beta, n_chan)
%NGV_SIG_TX NGV_SIG message transmitter/parser
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

% Initialize BCC encoder object for NGV_SIG
if isempty(bcc_obj)
    bcc_obj = comm.ConvolutionalEncoder( ...
        'TrellisStructure', poly2trellis(7, [133 171]), ...
        'TerminationMethod', 'Terminated');
else
    reset(bcc_obj);
end

if (any(PHY.mid == [4 8 16]))
    mid_setting = log2(PHY.mid) - 2; % NGV-SIG values 0,1,2 correspond to midamble periodicity of 4, 8, 16. Value 3 is reserved
else
    error('PHY.mid not supported')
end

% NGV-SIG fields, according to SFD IEEE 802.11-19/0497r6
b_ver   = de2bi(0, 2);              % PHY version, set to 0 for .11bd
b_bw    = PHY.n_chan - 1;           % 0: 10 MHz, 1: 20 MHz
b_mcs   = de2bi(PHY.mcs, 4);        % MCS value
b_Nss   = PHY.n_ss - 1;             % Number of spatial streams indicator
b_mid   = de2bi(mid_setting, 2);    % Midamble period setting
if (PHY.mcs == 10 && PHY.ngvltf_fmt == 2)
    b_ltf = 0;                      % when MCS==10, ltf_fmt is always 2 and b_ltf will be ignored
else
    b_ltf = PHY.ngvltf_fmt;            % LTF format for NGV-MCS 0-9, must be 0 or 1
end
b_extra = PHY.LDPC.extra;           % LDPC extra symbol
b_res   = ones(1, 2);               % reserved bits, set to 1

% Form basic NGV-SIG message without CRC
b_ngv_sig_basic = logical([b_ver, b_bw, b_mcs, b_Nss, b_mid, b_ltf, b_extra, b_res].');

b_crc8 = de2bi(crc8(b_ngv_sig_basic),8,'left-msb')';
b_ngv_sig_with_crc = [b_ngv_sig_basic; b_crc8(1:4)];

b_ngv_sig = logical([b_ngv_sig_with_crc; zeros(6, 1)]);

% Convolutional encoder
ngv_sig_enc = step(bcc_obj, b_ngv_sig);

% Interleaver
ngv_sig_int = interleaver(ngv_sig_enc(1:48), 1, 48, 1, 1);

% BPSK modulation
ngv_sig_mod = 2*ngv_sig_int - 1;

% Initialize base f-domain representation
ngv_sig_sp = zeros(64, 1);

% Map modulated symbols on data subcarriers
ngv_sig_sp(PHY.sig_data_idx) = ngv_sig_mod;

% Append pilots
ngv_sig_sp(PHY.sig_pilot_idx) = PHY.sig_pilot_val;

% Populate the subcarriers in the upper part of the 20 MHz channel, and perform phase rotation
% The upper part will be used only if transmitting a 20 MHz waveform
ngv_sig_sp2 = [ngv_sig_sp; 1j*ngv_sig_sp];

% Apply spectral shaping window
ngv_sig_sp_win = ngv_sig_sp2(1:64*n_chan).*kaiser(64*n_chan, w_beta);

% Time-domain SIG waveform
ngv_sig_wf_base = 1/sqrt(52*n_chan)*dot11_ifft(ngv_sig_sp_win, 64*n_chan);

% Append CP
ngv_sig_wf = [ngv_sig_wf_base(48*n_chan+1:64*n_chan); ngv_sig_wf_base];

end
