function [chan_obj, chan_name] = chan_mod_init(channel_model, bw_mhz, ovs, n_tx_ant, n_rx_ant)
%CHAN_MOD_INIT Channel model initialization according to Car-2-Car models
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

% If AWGN model is selected, return empty handle
if (channel_model == 0)
    chan_name = 'AWGN';
    chan_obj = [];
    return
end

% C2C models' names
channel_names = {'R-LOS' 'UA-LOS' 'C-NLOS' 'H-LOS' 'H-NLOS', ...
    'R-LOS-ENH' 'UA-LOS-ENH' 'C-NLOS-ENH' 'H-LOS-ENH' 'H-NLOS-ENH'};
chan_name = channel_names{channel_model};

% Get channel model PDP, p_dB in dB, tau in sec, dpl_shft in Hz.
switch chan_name
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
    case 'R-LOS-ENH'
        p_dB = [0 -12 -15];
        tau = [0 84 183]*1e-9;
        dpl_shft = [0 94 -1176];
    case 'UA-LOS-ENH'
        p_dB = [0 -11 -13 -15];
        tau = [0 222 334 533]*1e-9;
        dpl_shft = [0 224 1173 588];
    case 'C-NLOS-ENH'
        p_dB = [0 -3 -4 -7 -15];
        tau = [0 220 266 475 630]*1e-9;
        dpl_shft = [0 -142 -542 -155 320];
    case 'H-LOS-ENH'
        p_dB = [0 -11 -13 -17];
        tau = [0 167 433 600]*1e-9;
        dpl_shft = [0 1941 -1176 -391];
    case 'H-NLOS-ENH'
        p_dB = [0 -2 -5 -7 -15];
        tau = [0 100 500 867 1152]*1e-9;
        dpl_shft = [0 50 1157 -2352 1573];
end

% Use a very large K-factor for 1st tap (Static - pure Rician), zero for remaining taps (pure Rayleigh)
RicianFactor = [1e12 zeros(1, length(tau) - 1)];

% Maximum Doppler shift for all paths (identical)
fd = max(abs(dpl_shft));

% Initialize Doppler spectrum cell
doppler_spec = cell(size(dpl_shft));

% First tap is static (zero offset)
doppler_spec{1} = doppler('Asymmetric Jakes', [-.02 .02]);

% Remaining taps follow an Asymmetiric Jakes distribution (or "Half-Bathtub")
for ii = 2:length(dpl_shft)
    doppler_spec{ii} = doppler('Asymmetric Jakes', sort([0 dpl_shft(ii)/fd]));
end

% Create channel object
chan_obj = comm.MIMOChannel (...
    'KFactor',                  RicianFactor, ...
    'DirectPathDopplerShift', 	zeros(size(RicianFactor)), ...
    'DirectPathInitialPhase', 	zeros(size(RicianFactor)), ...
    'DopplerSpectrum',          doppler_spec, ...
    'SampleRate',               ovs*bw_mhz*1e6, ...
    'PathDelays',               tau, ...
    'AveragePathGains',         p_dB, ...
    'MaximumDopplerShift',      fd, ...
    'FadingDistribution',         'Rician', ...
    'NormalizePathGains',         true, ...
    'NormalizeChannelOutputs',    false, ...
    'TransmitCorrelationMatrix',  eye(n_tx_ant), ...
    'ReceiveCorrelationMatrix',   eye(n_rx_ant) ...
    );

end
