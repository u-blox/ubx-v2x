function [SIG_CFG] = sig_rx(x_d, snr)
%SIG_RX SIG message receiver/deparser
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

% LLR demapping
llr_in = llr_demap(x_d.', 1, snr);

% Deinterleaving
x_data = deinterleaver(llr_in, 1, 48, 1, 0);

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
        otherwise
            return
    end
    
    % Declare non-erroneous SIG after valid MCS detection
    SIG_CFG.sig_err = false;
else
    return
end

end
