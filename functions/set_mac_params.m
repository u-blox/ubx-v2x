function MAC = set_mac_params(mcs, payload_len)
%SET_MAC_PARAMS Initialize MAC parameters
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

MAC.length  = payload_len;   % Payload length in bytes
MAC.mcs     = mcs;           % Modulation and Coding Scheme

% Generate input data from MAC
tmp_msg = randi([0 255], payload_len - 4, 1)'; % Create pseudo-random PSDU binary message from MAC

% Calculate CRC-32
data_msg_crc = crc32(tmp_msg);

% Convert byte to binary data
tmp_data = logical(de2bi(data_msg_crc, 8))';
MAC.data_msg = tmp_data(:);

% Initialize scrambler with a 7-bit non-allzero PN sequence (random or pre-set)
MAC.pn_seq = logical(de2bi(randi([1 127]), 7, 'left-msb'))';

end
