function [tx_wf, data_f_mtx, data_msg_crc, tx_parity_bytes, PHY] = sim_tx(mcs, payload_len, rs_enabled, rsEncoder)
%SIM_RX High-level transmitter function
%
%   Author: Ioannis Sarris, u-blox
%   email: ioannis.sarris@u-blox.com
%   August 2018; Last revision: 30-August-2018

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
[PHY, data_msg, data_msg_crc] = tx_phy_params(mcs, payload_len);

% Get STF waveform
stf_wf = stf_tx();

% Get LTF waveform
ltf_wf = ltf_tx();

% Get SIG waveform
sig_wf = sig_tx(PHY);

% Calculate number of required pad bits
pad_len = PHY.n_sym*PHY.n_dbps - (16 + 8*PHY.length + 6);

% Add service and zero-padding (pad + tail)
padding_out = [false(16, 1); data_msg; false(pad_len + 6, 1)];

% Generate RS parity packet
if (rs_enabled)
    tx_parity_bytes = GenParityPacket(rsEncoder, data_msg_crc');
    PHY.n_bytes_parity = size(tx_parity_bytes, 1);
    PHY.n_sym_parity = ceil(8*PHY.n_bytes_parity/PHY.n_dbps);
    
    % Convert byte to binary data
    data_msg_parity = logical(de2bi(tx_parity_bytes', 8))';
    data_msg_parity = data_msg_parity(:);
    
    % Calculate number of required pad bits for parity
    PHY.pad_len_parity = (PHY.n_sym + PHY.n_sym_parity)*PHY.n_dbps - (16 + 8*(PHY.length + PHY.n_bytes_parity) + 6) - pad_len;
    
    % Append parity and extra zero-padding
    padding_out = [padding_out; data_msg_parity; false(PHY.pad_len_parity, 1)];
else
    PHY.n_bytes_parity = 0;
    PHY.n_sym_parity = 0;
    PHY.pad_len_parity = 0;
    tx_parity_bytes = [];
end

% Generate data waveform
[data_wf, data_f_mtx] = data_tx(PHY, pad_len, padding_out);

% Concatenate output waveform
tx_wf = [stf_wf; ltf_wf; sig_wf; data_wf];

end
