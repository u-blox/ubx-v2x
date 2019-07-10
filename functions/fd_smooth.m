function h_out = fd_smooth(h_in, n_sd)
%FD_SMOOTH Frequency-domain smoothing
%
%   Author: Ioannis Sarris, u-blox
%   email: ioannis.sarris@u-blox.com
%   August 2018; Last revision: 10-July-2019

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

% Number of guard subcarriers
k = 6;
if (n_sd == 52)
    k = 4;
end

% Replicate missing values to enable smoothing
h_in(1:k, 1) = h_in((k + 1)*ones(1, k), 1);
h_in(33, 1) = (h_in(32, :) + h_in(34, 1))/2;
h_in((66 - k):64, 1) = h_in((65 - k)*ones(1, k - 1), 1);

% Moving-average smoothing
h_out = complex(zeros(64, 1));

% Apply length-3 window
h_out(2:63, 1) = h_in(1:62, 1)*.15 + h_in(2:63, 1)*.7 + h_in(3:64, 1)*.15;

end