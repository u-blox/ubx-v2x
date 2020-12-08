function PHY = ngv_sig_parse(NGV_SIG_CFG, sig_length)
%NGV_SIG_PARSE Parse NGV-SIG parameters into PHY structure
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

mcs          = NGV_SIG_CFG.mcs;
mid          = NGV_SIG_CFG.mid;
n_ss         = NGV_SIG_CFG.n_ss;
extra_sym    = NGV_SIG_CFG.extra;
ltf_fmt_init = NGV_SIG_CFG.b_ltf;
n_chan       = NGV_SIG_CFG.n_chan;
ppdu_fmt     = 2;

% Use tx_phy_params to obtain PHY structure. This ensures PHY always has the same fields and parameters at TX and RX
PHY  = tx_phy_params('RX', mcs, 0, ppdu_fmt, mid, n_ss, ltf_fmt_init, n_chan, sig_length, extra_sym);

end
