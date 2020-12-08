function out = mapper_tx(in, q)
%MAPPER_TX Modulation mapper
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

% Get all possible decimal values for q
q_vec = 0:2^q - 1;

dcm_enabled = false;
% Create modulation table and appropriate normalization factor
switch q
    case 0.5 % BPSK-DCM
        w = [-1 1].';
        dcm_enabled = true;
        q = 1; %update q value
        q_vec = 0:2^q - 1;
        ibits = q_vec;
        mod_table = w(ibits + 1);
        norm_factor = 1;
    case 1 % BPSK
        w = [-1 1].';
        ibits = q_vec;
        mod_table = w(ibits + 1);
        norm_factor = 1;
        
    case 2 % QPSK
        w = [-1 1].';
        ibits = floor(q_vec/2);
        qbits = bitand(q_vec, 1);
        mod_table = (w(ibits + 1) + 1j*w(qbits + 1));
        norm_factor = 1/sqrt(2);
        
    case 4 % 16-QAM
        w = (1/3)*[-3 -1 3 1].';
        ibits = floor(q_vec/4);
        qbits = bitand(q_vec, 3);
        mod_table = (w(ibits + 1) + 1j*w(qbits + 1));
        norm_factor = 3/sqrt(10);
        
    case 6 % 64-QAM
        w = (1/7)*[-7 -5 -1 -3 7 5 1 3].';
        ibits = floor(q_vec/8);
        qbits = bitand(q_vec, 7);
        mod_table = (w(ibits + 1) + 1j*w(qbits + 1));
        norm_factor = 7/sqrt(42);
        
    case 8 % 256-QAM
        w = (1/15)*[-15 -13 -9 -11 -1 -3 -7 -5 15 13 9 11 1 3 7 5].';
        ibits = floor(q_vec/16);
        qbits = bitand(q_vec, 15);
        mod_table = (w(ibits + 1) + 1j*w(qbits + 1));
        norm_factor = 15/sqrt(170);
        
    otherwise % Needed for code-generation
        mod_table = complex(zeros(0, 1));
        norm_factor = 1;
end

% Group bits per q
bin_vec = reshape(in, q, size(in, 1)/q).';

% Convert each set of q bits to decimal
dec_val = bi2de(bin_vec, 'left-msb');

% Modulation symbols are obtained by mapping to modulation table
out = norm_factor*mod_table(dec_val + 1, 1);

% DCM constellation mapping
if (dcm_enabled)
    n_sd = length(bin_vec);
    k = [0:n_sd - 1]';
    out = [out; exp(1j*(k + n_sd)*pi).*out];
end

end
