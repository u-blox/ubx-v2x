function out = crc32(in)
%CRC32 Appends CRC32 on an input bitstream
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

%% Initialize CRC
out = in;
crc  = uint32(hex2dec('FFFFFFFF'));
poly = uint32(hex2dec('EDB88320'));
data = uint8(out);

%% Compute CRC-32 value
mask = uint32(0);
for i = 1:length(data)
    crc = bitxor(crc,uint32(data(i)));
    for j = 1:8
        mask(:) = bitcmp(bitand(crc, uint32(1)));
        if (mask == uint32(2^32 - 1))
            mask(:) = 0;
        else
            mask(:) = mask + 1;
        end
        crc = bitxor(bitshift(crc, -1), bitand(poly, mask));
    end
end
m = bitcmp(crc);

%% Output vector
out = [out, bitand(m,255), bitand(bitshift(m,-8),255), bitand(bitshift(m,-16),255), bitshift(m,-24)];

end
