function PHY = sig_parse(SIG_CFG)
%SIG_PARSE Parse SIG parameters into PHY structure
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

mcs          = SIG_CFG.mcs;
sig_length   = SIG_CFG.length;
mid          = 0;
n_ss         = 0;
extra_sym    = 0;
ltf_fmt_init = 0;
n_chan       = 1;
ppdu_fmt     = 1;
payload_len  = 0;

% Use tx_phy_params to obtain PHY structure. This ensures PHY always has the same fields and parameters at TX and RX
PHY = tx_phy_params('RX', mcs, payload_len, ppdu_fmt, mid, n_ss, ltf_fmt_init, n_chan, sig_length, extra_sym);

end