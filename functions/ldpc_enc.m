function cod_bits = ldpc_enc(LDPC, data_in)
%LDPC_ENC Encodes a binary stream with LDPC coding
%
%   Author: Ioannis Sarris, u-blox
%   email: ioannis.sarris@u-blox.com
%   March 2019; Last revision: 10-July-2019

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

% LDPC parameters
Ncw = LDPC.Ncw;
K0 = LDPC.K0;
Navbits = LDPC.Navbits;
vNshrt = LDPC.vNshrt;
vNpunc = LDPC.vNpunc;
vNrepRem = LDPC.vNrepRem;
vNrepInt = LDPC.vNrepInt;
vCwLen = LDPC.vCwLen;
Lldpc = LDPC.Lldpc;
rate = LDPC.rate;

% Initialize LDPC object
tx_ldpc_code = LDPCCode(0, 0);
tx_ldpc_code.load_wifi_ldpc(Lldpc, rate);

% Initialize indices & variables
idx1 = 0;
idx2 = 0;
cod_bits = false(Navbits, 1);

for i_cw = 1:Ncw
    
    n_info = K0 - vNshrt(i_cw); % number of pay-load bits in systematic part
    
    % Add shortening (zero) bits
    unc_bits = [data_in((1:n_info) + idx1); zeros(vNshrt(i_cw), 1)];
    
    % Increase index counter
    idx1 = idx1 + n_info;
    
    % LDPC encoding
    cod_bits_temp = tx_ldpc_code.encode_bits(unc_bits);
    
    % Remove shortening bits
    inf_bits = cod_bits_temp(1:K0 - vNshrt(i_cw));
    
    % Puncture parity bits
    par_bits = cod_bits_temp(K0 + 1:Lldpc - vNpunc(i_cw));
    
    temp_cw = [inf_bits; par_bits];
    
    if vNpunc(i_cw) > 0
        % Assemble LDPC codeword
        cod_bits((1:vCwLen(i_cw)) + idx2) = temp_cw;
    else    
        % Integer repetition bits (for 11n compatibility)
        if vNrepInt(i_cw) > 0
            rep_bits = repmat(temp_cw, vNrepInt(i_cw), 1);
        else
            rep_bits = zeros(0, 1);
        end
        
        % Assemble LDPC codeword, appending any fractional repetition bits at the end
        cod_bits((1:vCwLen(i_cw)) + idx2) = [temp_cw; rep_bits; temp_cw(1:vNrepRem(i_cw))];
    end
    
    % Increase output vector index
    idx2 = idx2 + vCwLen(i_cw);
end

end