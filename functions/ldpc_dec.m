function unc_bits = ldpc_dec(LDPC, llr_in)
%LDPC_DEC Decodes an LLR stream with LDPC decoding
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
vNshrt = LDPC.vNshrt;
vNrepRem = LDPC.vNrepRem;
vNrepInt = LDPC.vNrepInt;
vCwLen = LDPC.vCwLen;
Nshrt = LDPC.Nshrt;
Lldpc = LDPC.Lldpc;
rate = LDPC.rate;

% Initialize indices & variables
idx1 = 1;
idx2 = 1;
unc_bits = zeros(Ncw*K0 - Nshrt, 1);

% Initialize LDPC object
rx_ldpc_code = LDPCCode(0, 0);
rx_ldpc_code.load_wifi_ldpc(Lldpc, rate);

% Loop for LDPC codewords
for i_cw = 1:Ncw
    
    % Define information bits and shortening bits lengths per codeword
    inf_bits_len = K0 - vNshrt(i_cw);
    short_len = vNshrt(i_cw);
    
    % Parity length
    par_len = rx_ldpc_code.M - LDPC.vNpunc(i_cw);
    
    % Check if CW length is incorrectly received to avoid errors
    if length(llr_in) >= (idx1 + vCwLen(i_cw) - 1)
        
        % Extract soft bits for current codeword
        X_cw = llr_in(idx1:idx1 + vCwLen(i_cw) - 1);
        
        % Increase index of coded soft bits
        idx1 = idx1 + vCwLen(i_cw);
        
        % Define length of repetition bits
        rep_len = vNrepRem(i_cw);
        int_rep = vNrepInt(i_cw);
        
        % Check if repetition is applicable
        if (rep_len > 0) || (int_rep > 0)
            
            % Calculate padding length to fit data on multiples of (inf_bits_len + par_len)
            pad_length = (int_rep + 2)*(inf_bits_len + par_len) - vCwLen(i_cw);
            
            % Append zeros
            X_cw_pad = [X_cw; zeros(pad_length, 1)];
            
            % Reshape into a matrix
            X_mat = reshape(X_cw_pad, (inf_bits_len + par_len), (int_rep + 2));
            
            % Add columns to increase SNR of soft-bits
            X_cw = sum(X_mat, 2)/(int_rep + 2);
        end
        
        % Initialize coded bits vector
        cod_bits = zeros(Lldpc, 1);
        
        % Place information bits at the beginning
        cod_bits(1:inf_bits_len) = X_cw(1:inf_bits_len);
        
        % Set shortening (zero) bits to highest soft value
        cod_bits(inf_bits_len + 1:inf_bits_len + short_len) = max(X_cw);
        
        % Place parity bits at the end
        cod_bits(inf_bits_len + short_len + 1:inf_bits_len + short_len + par_len) = X_cw(inf_bits_len + 1:inf_bits_len + par_len);
        
        % LDPC decoding
        [unc_bits_temp, ~] = rx_ldpc_code.decode_llr(cod_bits, 50, 1);
        
        % Concatenate uncoded bits to a vector
        unc_bits(idx2:idx2 + inf_bits_len - 1) = unc_bits_temp(1:inf_bits_len);
        
        % Increase index of uncoded hard bits
        idx2 = idx2 + inf_bits_len;
    end
end

end
