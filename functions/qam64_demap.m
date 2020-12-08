function llr_out = qam64_demap(sym_in)
%QAM64_DEMAP Performs demapping of QAM-64 modulation
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

% Initialize output LLR vector
llr_out = zeros(3, size(sym_in, 2));

% Find regions of input symbols
idx_1 = (abs(sym_in) > 6);
idx_2 = (abs(sym_in) <= 6) & (abs(sym_in) > 4);
idx_3 = (abs(sym_in) <= 4) & (abs(sym_in) > 2);
idx_4 = (abs(sym_in) <= 2);

% Calculate LLRs (1st soft-bit) using a different equation for each region
llr_out(1, idx_1) = 16*sym_in(idx_1) - sign(sym_in(idx_1))*48;
llr_out(1, idx_2) = 12*sym_in(idx_2) - sign(sym_in(idx_2))*24;
llr_out(1, idx_3) = 8*sym_in(idx_3) - sign(sym_in(idx_3))*8;
llr_out(1, idx_4) = 4*sym_in(idx_4);

% Find regions of input symbols
idx_1 = (abs(sym_in) > 6);
idx_2 = (abs(sym_in) <= 6) & (abs(sym_in) > 2);
idx_3 = (abs(sym_in) <= 2);

% Calculate LLRs (2nd soft-bit) using a different equation for each region
llr_out(2, idx_1) = -8*abs(sym_in(idx_1)) + 40;
llr_out(2, idx_2) = -4*abs(sym_in(idx_2)) + 16;
llr_out(2, idx_3) = -8*abs(sym_in(idx_3)) + 24;

% Find regions of input symbols
idx_1 = (abs(sym_in) > 4);
idx_2 = (abs(sym_in) <= 4);

% Calculate LLRs (3rd soft-bit) using a different equation for each region
llr_out(3, idx_1) = -4*abs(sym_in(idx_1)) + 24;
llr_out(3, idx_2) = 4*abs(sym_in(idx_2)) - 8;

end
