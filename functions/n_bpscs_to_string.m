function [modulation_scheme_string] = n_bpscs_to_string(n_bpscs)
%N_BPSCS_TO_STRING Convert number of bits per modulation symbol to readable string
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

if (n_bpscs == 0.5)
    modulation_scheme_string = 'BPSK-DCM';
elseif (n_bpscs == 1)
    modulation_scheme_string = 'BPSK';
elseif (n_bpscs == 2)
    modulation_scheme_string = 'QPSK';
else
    modulation_scheme_string = sprintf('%d-QAM',2^n_bpscs);
end

end
