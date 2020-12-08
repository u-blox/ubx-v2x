function [NGV_SIG_CFG] = ngv_sig_rx(x_d_cfo, snr)
%NGV_SIG_RX NGV-SIG message receiver
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

% Create system object
if isempty(vit_obj)
    vit_obj = comm.ViterbiDecoder(...
        'TrellisStructure', poly2trellis(7, [133 171]), ...
        'InputFormat', 'Unquantized', ...
        'TracebackDepth', 24, ...
        'TerminationMethod', 'Terminated');
end

% LLR demapping
llr_in = llr_demap(x_d_cfo.', 1, snr);

% Deinterleaving
x_data = deinterleaver(llr_in, 1, 48, 1, 0);

% Viterbi decoding
sig_msg = step(vit_obj, x_data.');

% Extract parameters from NGV-SIG
NGV_SIG_CFG.ver     = bi2de(sig_msg(1:2)');
NGV_SIG_CFG.n_chan  = bi2de(sig_msg(3)) + 1;
NGV_SIG_CFG.mcs     = bi2de(sig_msg(4:7)');
NGV_SIG_CFG.n_ss    = bi2de(sig_msg(8)) + 1; % Number of spatial streams
NGV_SIG_CFG.mid     = 2^(2 + bi2de(sig_msg(9:10)')); % SFD: Set 0 for 4 symbols, set 1 for 8 symbols, set 2 for 16 symbol. Value 3 is reserved.
NGV_SIG_CFG.b_ltf   = sig_msg(11);
NGV_SIG_CFG.extra   = sig_msg(12);
NGV_SIG_CFG.res     = bi2de(sig_msg(13:14)');
NGV_SIG_CFG.crc     = bi2de(sig_msg(15:18)');

% Declare non-erroneous SIG after valid MCS detection
NGV_SIG_CFG.sig_err = false;

% Perform CRC check
b_crc8 = de2bi(crc8(sig_msg(1:14)),8,'left-msb')';
crc_error = (bi2de(b_crc8(1:4)') ~= NGV_SIG_CFG.crc);

% Validity checks for NGV_SIG
check0 = (NGV_SIG_CFG.mcs > 10);
check1 = (crc_error == true);
check2 = (NGV_SIG_CFG.mid == 32); % value '11' in the mid field (resulting in mid==32) is reserved.
check3 = (NGV_SIG_CFG.mcs == 9 && NGV_SIG_CFG.n_chan == 1); % MCS 9 is only supported in 20 MHz mode
check4 = (NGV_SIG_CFG.ver ~= 0);
check5 = (NGV_SIG_CFG.res ~= 3);

if (check0 || check1 || check2 || check3 || check4 || check5)
    NGV_SIG_CFG.sig_err = true;
    return
end

end
