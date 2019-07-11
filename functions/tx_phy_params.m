function [PHY, LDPC, data_msg] = tx_phy_params(mcs, payload_len, ppdu_fmt, ldpc_en, mid_period)
%TX_PHY_PARAMS Initializes PHY layer parameters
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

% Store MCS / payload length
PHY.mcs         = mcs;
PHY.length      = payload_len;
PHY.ppdu_fmt    = ppdu_fmt;
PHY.ldpc_en     = ldpc_en;
PHY.mid_period  = mid_period;

% Initialize scrambler with a 7-bit non-allzero PN sequence (random or pre-set)
PHY.pn_seq = logical(de2bi(randi([1 127]), 7, 'left-msb'))';

% Pilot subcarrier indices and values
PHY.pilot_idx = [-21 -7 7 21].' + 33;
PHY.pilot_val = [1 1 1 -1].';

% Polarity signs to use for pilots
PHY.polarity_sign = [1,1,1,1,-1,-1,-1,1,-1,-1,-1,-1,1,1,-1,1,-1,-1,1,1,-1,1,1,-1,1,1,1,1,1,1,-1,1,1,1,-1,1,1,-1,-1,1,1,1, ...
    -1,1,-1,-1,-1,1,-1,1,-1,-1,1,-1,-1,1,1,1,1,1,-1,-1,1,1,-1,-1,1,-1,1,-1,1,1,-1,-1,-1,1,1,-1,-1,-1,-1,1,-1,-1,1, ...
    -1,1,1,1,1,-1,1,-1,1,-1,1,-1,-1,-1,-1,-1,1,-1,1,1,-1,1,-1,1,1,1,-1,-1,1,-1,-1,-1,1,1,1,-1,-1,-1,-1,-1,-1,-1].';

% Starting index for pilot polarity index
PHY.pilot_offset = 1;

% SIG data subcarrier indices
PHY.sig_idx = [-26:-22 -20:-8 -6:-1 1:6 8:20 22:26].' + 33;

% Legacy (1) or NGV (2) PPDU format
if (ppdu_fmt == 1)
    % Number of data subcarriers
    n_sd = 48;
    
    % Data subcarrier indices
    PHY.data_idx = [-26:-22 -20:-8 -6:-1 1:6 8:20 22:26].' + 33;
    
elseif (ppdu_fmt == 2)
    
    % Number of data subcarriers
    n_sd = 52;
    
    % Data subcarrier indices
    PHY.data_idx = [-28:-22 -20:-8 -6:-1 1:6 8:20 22:28].' + 33;
else
    % Prevent errors in code generation
    n_sd = 0;
    PHY.data_idx = 0;
end

% MCS tables for coding rate (numerator / denominator) and bits per modulation symbol
rate_num = [1 3 1 3 1 3 2 3 5 3];
rate_denom = [2 4 2 4 2 4 3 4 6 4];
n_bpscs = [1 1 2 2 4 4 6 6 6 8];

% Find code rate numerator/denominator & bits per modulation symbol
PHY.r_num   = rate_num(mcs + 1);
PHY.r_denom = rate_denom(mcs + 1);
PHY.n_bpscs = n_bpscs(mcs + 1);

% Calculate coded/uncoded number of bits per OFDM symbol
n_cbps  = n_sd*n_bpscs(mcs + 1);
n_dbps  = n_sd*n_bpscs(mcs + 1)*rate_num(mcs + 1)/rate_denom(mcs + 1);

% Extra step to enable code generation
PHY.n_sd    = n_sd;
PHY.n_cbps  = n_cbps;
PHY.n_dbps  = n_dbps;

% Calculate number of OFDM symbols, different value for LDPC/BCC
PHY.n_sym = ceil((16 + 8*payload_len)/n_dbps);
LDPC = ldpc_enc_params(payload_len, n_dbps, n_cbps);
if ldpc_en
    PHY.n_sym = LDPC.Nsym;
else
    PHY.n_sym = ceil((16 + 8*payload_len + 6)/n_dbps);
end

% Create pseudo-random PSDU binary message (account for CRC-32)
tmp_msg = randi([0 255], payload_len - 4, 1)';

% Calculate CRC-32
data_msg_crc = crc32(tmp_msg);

% Convert byte to binary data
data_msg = logical(de2bi(data_msg_crc, 8))';
data_msg = data_msg(:);

end
