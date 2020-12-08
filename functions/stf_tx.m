function stf_wf = stf_tx(w_beta, n_chan)
%STF_TX Generates STF preamble
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

% Store this as a persistent variable to avoid recalculation
persistent stf_wf_10 stf_wf_20

if isempty(stf_wf_10)
    % STF f-domain represenation (including DC-subcarrier & guard bands)
    stf_f = sqrt(1/2)*...
        [zeros(1,6), 0 0 1+1j 0 0 0 -1-1j 0 0 0 1+1j 0 0 0 -1-1j 0 0 0 -1-1j 0 0 0 1+1j 0 0 0 ...
        0 0 0 0 -1-1j 0 0 0 -1-1j 0 0 0 1+1j 0 0 0 1+1j 0 0 0 1+1j 0 0 0 1+1j 0 0, zeros(1, 5)].';
    
    % Apply spectral shaping window
    stf_f = stf_f.*kaiser(64, w_beta);
    
    % Base STF waveform
    stf_wf_base = 1/sqrt(12)*dot11_ifft(stf_f, 64);
    
    % Append CP
    stf_wf_10 = [stf_wf_base(33:64); stf_wf_base; stf_wf_base];
end

if isempty(stf_wf_20)
    n_chan_temp = 2;
    % Original 10 MHz STF in f-domain
    stf_f10 = sqrt(1/2)*...
        [zeros(1,6), 0 0 1+1j 0 0 0 -1-1j 0 0 0 1+1j 0 0 0 -1-1j 0 0 0 -1-1j 0 0 0 1+1j 0 0 0 ...
        0 0 0 0 -1-1j 0 0 0 -1-1j 0 0 0 1+1j 0 0 0 1+1j 0 0 0 1+1j 0 0 0 1+1j 0 0, zeros(1, 5)].';
    
    % Transmit STF in both 10 MHz subchannels, apply tone rotation to upper channel
    stf_f20 = [stf_f10; 1j*stf_f10];
    
    % Apply spectral shaping window
    % TODO: check if window should instead be applied individually to each subchannel
    stf_f = stf_f20(1:64*n_chan_temp).*kaiser(64*n_chan_temp, w_beta);
    
    % Base STF waveform
    stf_wf_base20 = 1/sqrt(12*n_chan_temp)*dot11_ifft(stf_f, 64*n_chan_temp);
    
    % Append CP
    stf_wf_20 = [stf_wf_base20(32*n_chan_temp+1:64*n_chan_temp); stf_wf_base20; stf_wf_base20];
end

% Choose appropriate value for 10 MHz / 20 MHz
if (n_chan == 1)
    stf_wf = stf_wf_10;
elseif (n_chan == 2)
    stf_wf = stf_wf_20;
else
    error('not supported')
end

end
