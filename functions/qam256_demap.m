function llr_out = qam256_demap(sym_in)
%QAM256_DEMAP LLR demapping for 256-QAM
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

llr_out = zeros(4, size(sym_in, 2));

idx_1 = (abs(sym_in) > 14);
idx_2 = (abs(sym_in) <= 14) & (abs(sym_in) > 12);
idx_3 = (abs(sym_in) <= 12) & (abs(sym_in) > 10);
idx_4 = (abs(sym_in) <= 10) & (abs(sym_in) > 8);
idx_5 = (abs(sym_in) <= 8) & (abs(sym_in) > 6);
idx_6 = (abs(sym_in) <= 6) & (abs(sym_in) > 4);
idx_7 = (abs(sym_in) <= 4) & (abs(sym_in) > 2);
idx_8 = (abs(sym_in) <= 2);

llr_out(1, idx_1) = 32*sym_in(idx_1) - sign(sym_in(idx_1))*224;
llr_out(1, idx_2) = 28*sym_in(idx_2) - sign(sym_in(idx_2))*168;
llr_out(1, idx_3) = 24*sym_in(idx_3) - sign(sym_in(idx_3))*120;
llr_out(1, idx_4) = 20*sym_in(idx_4) - sign(sym_in(idx_4))*80;
llr_out(1, idx_5) = 16*sym_in(idx_5) - sign(sym_in(idx_5))*48;
llr_out(1, idx_6) = 12*sym_in(idx_6) - sign(sym_in(idx_6))*24;
llr_out(1, idx_7) = 8*sym_in(idx_7) - sign(sym_in(idx_7))*8;
llr_out(1, idx_8) = 4*sym_in(idx_8);

idx_1 = (abs(sym_in) > 14);
idx_2 = (abs(sym_in) <= 14) & (abs(sym_in) > 12);
idx_3 = (abs(sym_in) <= 12) & (abs(sym_in) > 10);
idx_4 = (abs(sym_in) <= 10) & (abs(sym_in) > 6);
idx_5 = (abs(sym_in) <= 6) & (abs(sym_in) > 4);
idx_6 = (abs(sym_in) <= 4) & (abs(sym_in) > 2);
idx_7 = (abs(sym_in) <= 2);

llr_out(2, idx_1) = -16*abs(sym_in(idx_1)) + 176;
llr_out(2, idx_2) = -12*abs(sym_in(idx_2)) + 120;
llr_out(2, idx_3) = -8*abs(sym_in(idx_3)) + 72;
llr_out(2, idx_4) = -4*abs(sym_in(idx_4)) + 32;
llr_out(2, idx_5) = -8*abs(sym_in(idx_5)) + 56;
llr_out(2, idx_6) = -12*abs(sym_in(idx_6)) + 72;
llr_out(2, idx_7) = -16*abs(sym_in(idx_7)) + 80;

idx_1 = (abs(sym_in) > 14);
idx_2 = (abs(sym_in) <= 14) & (abs(sym_in) > 10);
idx_3 = (abs(sym_in) <= 10) & (abs(sym_in) > 8);
idx_4 = (abs(sym_in) <= 8) & (abs(sym_in) > 6);
idx_5 = (abs(sym_in) <= 6) & (abs(sym_in) > 2);
idx_6 = (abs(sym_in) <= 2);

llr_out(3, idx_1) = -8*abs(sym_in(idx_1)) + 104;
llr_out(3, idx_2) = -4*abs(sym_in(idx_2)) + 48;
llr_out(3, idx_3) = -8*abs(sym_in(idx_3)) + 88;
llr_out(3, idx_4) = 8*abs(sym_in(idx_4)) - 40;
llr_out(3, idx_5) = 4*abs(sym_in(idx_5)) - 16;
llr_out(3, idx_6) = 8*abs(sym_in(idx_6)) - 24;

idx_1 = (abs(sym_in) > 12);
idx_2 = (abs(sym_in) <= 12) & (abs(sym_in) > 8);
idx_3 = (abs(sym_in) <= 8) & (abs(sym_in) > 4);
idx_4 = (abs(sym_in) <= 4);

llr_out(4, idx_1) = -4*abs(sym_in(idx_1)) + 56;
llr_out(4, idx_2) = 4*abs(sym_in(idx_2)) - 40;
llr_out(4, idx_3) = -4*abs(sym_in(idx_3)) + 24;
llr_out(4, idx_4) = 4*abs(sym_in(idx_4)) - 8;

end
