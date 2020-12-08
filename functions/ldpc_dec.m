function unc_bits = ldpc_dec(LDPC, llr_in, ldpc_cfg)
%LDPC_DEC Decodes an LLR stream with LDPC decoding
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

% Matlab decoder is already compiled, ignore this function in codegen
coder.extrinsic('ldpc_dec_matlab');

% Initialize indices & variables
idx1 = 1;
idx2 = 1;
unc_bits = zeros(Ncw*K0 - Nshrt, 1);

% Loop for LDPC codewords
for i_cw = 1:Ncw
    
    % Define information bits and shortening bits lengths per codeword
    inf_bits_len = K0 - vNshrt(i_cw);
    short_len = vNshrt(i_cw);
    
    % Parity length
    ldpc_K = floor(Lldpc*rate);
    ldpc_M = Lldpc - ldpc_K;
    par_len = ldpc_M - LDPC.vNpunc(i_cw);
    
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
        unc_bits_temp = ldpc_dec_ext(LDPC.Lldpc, LDPC.rate, cod_bits, ldpc_cfg.iter, ldpc_cfg.minsum);
        
        % Concatenate uncoded bits to a vector
        unc_bits(idx2:idx2 + inf_bits_len - 1) = unc_bits_temp(1:inf_bits_len);
        
        % Increase index of uncoded hard bits
        idx2 = idx2 + inf_bits_len;
        
        % Early termination if the A-MPDU header in the first codeword is wrong (to speed up simulation for large payloads)
        if (i_cw == 1)
            rx_out = descrambler_rx(logical(unc_bits_temp));
            ampdu_eof = rx_out(10);
            ampdu_res = rx_out(11);
            ampdu_crc_val = crc8(rx_out(10:33));
            ampdu_crc_ok = (ampdu_crc_val == 12);
            ampdu_sig = bi2de(rx_out(34:41)', 'left-msb');
            if ~(ampdu_eof == 1 && ampdu_res == 1 && ampdu_sig == 78 && ampdu_crc_ok)
                % stop decoding further codewords
                break
            end
        end
    end
end

end
