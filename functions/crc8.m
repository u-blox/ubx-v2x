function out = crc8(in_bits)
%CRC8 Computes CRC8 on an input bitstream
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

% Example:
% in_bits = [1 1 1 1 0 0 0 1 0 0 1 0 0 1 1 0 0 0 0 0 0 0 0 0 1 1 1 0 0 0 0 0 0 0];
% output bits , where B7 is output first, are {1 0 1 0 1 0 0 0}.

% Example 2 (.11ax HE SIG 4-bit):
% in_bits = [1 1 0 1 1 1 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 1 1 0 0 0 0 0 0 0 0 0 0 0 1 0 0 1 1 0 1 0];
% the output bits , where B7 is output first, are {0 1 1 1}.

% Convert input data into booleans
data = logical(in_bits);

% Initialize shift register to all ones
register = uint8(255);

% Compute CRC-8 value
for i = 1:length(data)
    feedback_bit = bitxor(logical(bitget(register, 8)), data(i));
    feedback_vec = feedback_bit*7;
    register = bitshift(register, 1);
    register = bitxor(register, feedback_vec);
end

out = bitcmp(register);

end
