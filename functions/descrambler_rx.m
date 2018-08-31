function out = descrambler_rx(in, bcc_init)
%DESCRAMBLER Bit descrambler
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

persistent pn_seq

% Initialize descrambler if not initialized
if bcc_init || isempty(pn_seq)
    tmp_in = in(8:end, 1);
    pn_seq = in(7:-1:1, 1);
else
    tmp_in = in;
end

% Perform scrambling (identical to descrabling)
[pn_seq, out] = scrambler_tx(tmp_in, pn_seq);

end
