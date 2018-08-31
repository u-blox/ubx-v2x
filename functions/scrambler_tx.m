function [pn_state, out] = scrambler_tx(in, pn_state)
%SCRAMBLER Bit scrambler
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

% Initialize output
len = length(in);
out = false(len, 1);

% Perform scrambling per bit, use PN = X^7 + X^4 + 1
for ii = 1:len
    tmp1 = xor(pn_state(7), pn_state(4));
    tmp2 = pn_state(1:6, 1);
    pn_state(1, 1) = tmp1;
    pn_state(2:7, 1) = tmp2;
    out(ii) = xor(in(ii), pn_state(1));
end

end
