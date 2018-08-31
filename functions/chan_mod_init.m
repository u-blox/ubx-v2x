function h = chan_mod_init(channel_model)
%CHAN_MOD_INIT Channel model initialization according to Car-2-Car models
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

% If AWGN model is selected, return empty handle
if (channel_model == 0)
    h = [];
    return
end

% C2C models' names
Channels_Name = {'R-LOS' 'UA-LOS' 'C-NLOS' 'H-LOS' 'H-NLOS'};

% Get channel model PDP, p_dB in dB, tau in sec, dpl_shft in Hz.
switch Channels_Name{channel_model}
    case 'R-LOS'
        p_dB = [0 -14 -17];
        tau = [0 83 183]*1e-9;
        dpl_shft = [0 492 -295];
    case 'UA-LOS'
        p_dB = [0 -8 -10 -15];
        tau = [0 117 183 333]*1e-9;
        dpl_shft = [0 236 -157 492];
    case 'C-NLOS'
        p_dB = [0 -3 -5 -10];
        tau = [0 267 400 533]*1e-9;
        dpl_shft = [0 295 -98 591];
    case 'H-LOS'
        p_dB = [0 -10 -15 -20];
        tau = [0 100 167 500]*1e-9;
        dpl_shft = [0 689 -492 886];
    case 'H-NLOS'
        p_dB = [0 -2 -5 -7];
        tau = [0 200 433 700]*1e-9;
        dpl_shft = [0 689 -492 886];
end

% Doppler spectrum
dopl_spectr = doppler('Jakes');

% Use a very large K-factor for 1st tap (Static - pure Rician), zero for remaining taps (pure Rayleigh)
RicianFactor = [1e12 zeros(1, length(tau) - 1)];

% Maximum Doppler shift for all paths (identical)
fd = max(abs(dpl_shft));

% Create channel object
h = comm.RicianChannel (...
    'KFactor',                  RicianFactor, ...
    'DirectPathDopplerShift', 	dpl_shft, ...
    'DirectPathInitialPhase', 	zeros(size(RicianFactor)), ...
    'DopplerSpectrum',          dopl_spectr, ...
    'SampleRate',               10*1e6,...
    'PathDelays',               tau,...
    'AveragePathGains',         p_dB,...
    'MaximumDopplerShift',      fd...
    );

end
