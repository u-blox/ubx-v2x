function [SIG_CFG, r_cfo] = sig_rx(r, h_est, data_idx, pilot_idx, ldpc_en)
%SIG_RX SIG message receiver/deparser
%
%   Author: Ioannis Sarris, u-blox
%   email: ioannis.sarris@u-blox.com
%   August 2018; Last revision: 10-July-2019

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
persistent vit_obj

% Initialize structure
SIG_CFG = struct(...
    'length', 0, ...
    'mcs', 0, ...
    'sig_err', true, ...
    'r_num', 0, ...
    'r_denom', 0, ...
    'n_bpscs', 0, ...
    'n_cbps', 0, ...
    'n_dbps', 0, ...
    'n_sym', 0, ...
    'ppdu_fmt', 0, ...
    'n_sd', 0);

% Create system object
if isempty(vit_obj)
    vit_obj = comm.ViterbiDecoder(...
        'TrellisStructure', poly2trellis(7, [133 171]), ...
        'InputFormat', 'Unquantized', ...
        'TracebackDepth', 24, ...
        'TerminationMethod', 'Terminated');
end

% Perform FFT & normalization
y = complex(zeros(64, 1));
y(:) = dot11_fft(r([9:64 1:8], 1), 64)*sqrt(52)/64;

% Frequency-domain smoothing
h_est = fd_smooth(h_est, 48);

% Pilot equalization
x_p = y(pilot_idx, 1)./h_est(pilot_idx, 1).*[1 1 1 -1].';

% Residual CFO estimation
r_cfo = mean(angle(x_p));

% Data equalization with CFO compensation
x_d = y(data_idx, 1)./h_est(data_idx, 1)*exp(-1j*r_cfo);

% SNR input to Viterbi
snr = abs(h_est(data_idx, 1));

% LLR demapping
llr_in = llr_demap(x_d.', 1, snr);

% Deinterleaving
x_data = deinterleaver(llr_in, 1, 48, 1);

% Viterbi decoding
sig_msg = step(vit_obj, x_data.');

% Compare even parity to detect errors in L-SIG
parity_bit = sig_msg(18);
parity_check = mod(sum(sig_msg(1:17, 1)), 2);

% Check parity bit
if (parity_bit == parity_check)
    
    % Length from L-SIG in octets
    SIG_CFG.length = bi2de(sig_msg(6:17, 1)');
    
    % If length is invalid return (with error)
    if (SIG_CFG.length > 5)
        % Convert binary datarate to Mbps
        temp_rate = bi2de(sig_msg(1:4, 1)');
    else
        return
    end
    
    % Find MCS
    switch temp_rate
        case 11
            SIG_CFG.mcs = 0;
        case 15
            SIG_CFG.mcs = 1;
        case 10
            SIG_CFG.mcs = 2;
        case 14
            SIG_CFG.mcs = 3;
        case 9
            SIG_CFG.mcs = 4;
        case 13
            SIG_CFG.mcs = 5;
        case 8
            SIG_CFG.mcs = 6;
        case 12
            SIG_CFG.mcs = 7;
        case 4
            SIG_CFG.mcs = 8;
        case 2
            SIG_CFG.mcs = 9;
        otherwise
            return
    end
    
    % Declare non-erroneous SIG after valid MCS detection
    SIG_CFG.sig_err = false;
else
    return
end

% MCS table
r_num_vec   = [1 3 1 3 1 3 2 3 5 3];
r_denom_vec = [2 4 2 4 2 4 3 4 6 4];
n_bpscs_vec = [1 1 2 2 4 4 6 6 6 8];

% Find code rate numerator/denominator & bits per modulation symbol
SIG_CFG.r_num = r_num_vec(SIG_CFG.mcs + 1);
SIG_CFG.r_denom = r_denom_vec(SIG_CFG.mcs + 1);
SIG_CFG.n_bpscs = n_bpscs_vec(SIG_CFG.mcs + 1);

% Calculate coded/uncoded number of bits per OFDM symbol
SIG_CFG.n_cbps = 48*SIG_CFG.n_bpscs;
SIG_CFG.n_dbps = SIG_CFG.n_cbps*SIG_CFG.r_num/SIG_CFG.r_denom;

% Number of OFDM symbols
if ldpc_en
    SIG_CFG.n_sym = ceil((16 + 8*SIG_CFG.length)/SIG_CFG.n_dbps);
else
    SIG_CFG.n_sym = ceil((16 + 8*SIG_CFG.length + 6)/SIG_CFG.n_dbps);
end

end
