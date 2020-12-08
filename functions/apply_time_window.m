function out = apply_time_window(in, enabled)
%APPLY_TIME_WINDOW Apply time-domain window to improve spectral shape
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

% Default output is equal to input
out = in;

% Apply time-domain windowing
if enabled
    % Length of waveform
    wf_len = length(out);
    
    % Half the amplitude on first sample
    out(1, :) = out(1, :)/2;
    
    % OFDM symbol boundary samples
    idx = 80:80:wf_len - 80;
    
    % Perform widnowing on preamble & data fields
    out(idx + 1, :) = (out(idx + 1, :) + out(idx - 63, :))/2;
end

end