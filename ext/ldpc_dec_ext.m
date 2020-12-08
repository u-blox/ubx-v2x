function unc_bits_temp = ldpc_dec_ext(Lldpc, rate, cod_bits, iter_count, use_minsum)
%LDPC_DEC_EXT Decodes a single LDPC codeword using external decoder
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

% Store LDPC object to avoid re-generation
persistent ldpc_code

% Generate LDPC object
if isempty(ldpc_code)
    ldpc_code = LDPCCode(0, 0);
end

% Configure LDPC object
if ((ldpc_code.N ~= Lldpc) || (ldpc_code.K ~= floor(Lldpc*rate)))
    ldpc_code.load_wifi_ldpc(Lldpc, rate);
end

% Decode LLRs
[unc_bits_temp, ~] = ldpc_code.decode_llr(cod_bits, iter_count, use_minsum);

end
