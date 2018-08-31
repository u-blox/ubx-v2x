function llr_out = llr_demap(sym_in, q, snr_vec)
%LLR_DEMAP LLR demapping
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

% Initialize llr_out matrix
llr_out = zeros(q, size(sym_in, 2));

switch q
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
end

% Negative LLR values
llr_out = -llr_out.*snr_vec(:, ones(q, 1)).';

end
