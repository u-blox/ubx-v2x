function llr_out = llr_demap(sym_in, q, snr_vec)
%LLR_DEMAP LLR demapping
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


if q == 0.5
    % MCS 10, BPSK-DCM
    DCM = true;
    % The number of output data symbols is only half of the number of subcarriers
    n_sd = size(sym_in, 2) / 2;
    k = 0:n_sd - 1;
    % Initialize llr_out matrix
    llr_out = zeros(1, n_sd);
else
    % default, all other modulation schemes MCS 0-9
    DCM = false;
    k = 0; % for codegen
    n_sd = 0; % for codegen
    % Initialize llr_out matrix
    llr_out = zeros(q, size(sym_in, 2));
end

switch q
    case 0.5 % BSPK-DCM
        sym_A = 4*sym_in(1:n_sd);
        sym_B = 4*exp(-1j*(k + n_sd)*pi).*sym_in(n_sd + 1:2*n_sd);
        sym_A_scaled = sym_A.*snr_vec(1:n_sd, 1).';
        sym_B_scaled = sym_B.*snr_vec(n_sd + 1:2*n_sd, 1).';
        llr_out(1, :) = real(sym_A_scaled + sym_B_scaled);
        llr_out = -llr_out'; % Negative LLR values
    case 1 % BPSK
        xr = real(sym_in);
        llr_out(1, :) = 4*xr;
        
    case 2 % QPSK
        xr = real(sym_in)*sqrt(2);
        xi = imag(sym_in)*sqrt(2);
        llr_out(1, :) = 2*xr;
        llr_out(2, :) = 2*xi;
        
    case 4 % 16-QAM
        xr = real(sym_in)*sqrt(10);
        xi = imag(sym_in)*sqrt(10);
        llr_out(1:2, :) = qam16_demap(xr)/10;
        llr_out(3:4, :) = qam16_demap(xi)/10;
        
    case 6 % 64-QAM
        xr = real(sym_in)*sqrt(42);
        xi = imag(sym_in)*sqrt(42);
        llr_out(1:3, :) = qam64_demap(xr)/42;
        llr_out(4:6, :) = qam64_demap(xi)/42;
        
    case 8 % 256-QAM
        xr = real(sym_in)*sqrt(170);
        xi = imag(sym_in)*sqrt(170);
        llr_out(1:4, :) = qam256_demap(xr)/170;
        llr_out(5:8, :) = qam256_demap(xi)/170;
end

if (DCM == false)
    % Negative LLR values
    llr_out = -llr_out.*real(snr_vec(:, ones(q, 1))).';
end

end
