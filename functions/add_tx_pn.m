function out = add_tx_pn(in, enabled)
%ADD_TX_PN Apply phase noise at the transmitter
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

persistent pn_obj in_len

% Default output is equal to input
out = in;

if enabled
    % Define system object only on first run
    if isempty(pn_obj)
        % Length of vector
        in_len = length(in);
        
        % Phase noise power PSD at low frequency
        psd0   = -100;
        
        % Frequencies of pole-zero phase noise model
        fpole  = 250e3;
        fzero  = 7905.7e3;
        
        % Frequency points from 10 KHz up to (nearly) half the sampling rate
        f = 10.^linspace(4, log10(10e6/2 - 1e3), 20);
        
        % Phase noise PSD calculation
        psdf = pow2db(db2pow(psd0)*(1 + (f/fzero).^2)./(1 + (f/fpole).^2));
        
        % Create PN system object
        pn_obj = comm.PhaseNoise('Level', psdf, 'FrequencyOffset', f, 'SampleRate', 10e6);
    end
    
    % Check if object needs to be released in case of varying input length
    if (length(in) ~= in_len)
        in_len = length(in);
        release(pn_obj);
    end
    
    % Apply phase noise to input waveform
    out = pn_obj(in);
end

end