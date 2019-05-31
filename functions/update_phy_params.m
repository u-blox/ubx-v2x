function PHY = update_phy_params(PHY, mcs, payload_length)
%UPDATE_PHY_PARAMS Updates PHY layer parameters
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

% MCS tables for coding rate (numerator / denominator) and bits per modulation symbol
rate_num = [1 3 1 3 1 3 2 3];
rate_denom = [2 4 2 4 2 4 3 4];
n_bpscs = [1 1 2 2 4 4 6 6];

% Find code rate numerator/denominator & bits per modulation symbol
PHY.r_num   = rate_num(mcs + 1);
PHY.r_denom = rate_denom(mcs + 1);
PHY.n_bpscs = n_bpscs(mcs + 1);

% Calculate coded/uncoded number of bits per OFDM symbol
PHY.n_cbps  = 48*n_bpscs(mcs + 1);
PHY.n_dbps  = 48*n_bpscs(mcs + 1)*rate_num(mcs + 1)/rate_denom(mcs + 1);

% Calculate number of OFDM symbols
PHY.n_sym = ceil((16 + 8*length(payload_length) + 6)/(48*n_bpscs(mcs + 1)*rate_num(mcs + 1)/rate_denom(mcs + 1)));

end
