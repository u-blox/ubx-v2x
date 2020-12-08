function ltf_wf = ltf_tx(w_beta, n_chan)
%LTF_TX Generates LTF preamble
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
persistent ltf_wf_10 ltf_wf_20

if isempty(ltf_wf_10)
    % LTF f-domain represenation (including DC-subcarrier & guard bands)
    ltf_f = [zeros(1,6), 1 1 -1 -1 1 1 -1 1 -1 1 1 1 1 1 1 -1 -1 1 1 -1 1 -1 1 1 1 1 0 ...
        1 -1 -1 1 1 -1 1 -1 1 -1 -1 -1 -1 -1 1 1 -1 -1 1 -1 1 -1 1 1 1 1, zeros(1, 5)].';
    
    % Apply spectral shaping window
    ltf_f = ltf_f.*kaiser(64, w_beta);
    
    % Base LTF waveform
    ltf_wf_base = 1/sqrt(52)*dot11_ifft(ltf_f, 64);
    
    % Append CP
    ltf_wf_10 = [ltf_wf_base(33:64); ltf_wf_base; ltf_wf_base];
end

if isempty(ltf_wf_20)
    n_chan_temp = 2;
    % 10 MHz LTF in f-domain
    ltf_f10 = [zeros(1,6), 1 1 -1 -1 1 1 -1 1 -1 1 1 1 1 1 1 -1 -1 1 1 -1 1 -1 1 1 1 1 0 ...
        1 -1 -1 1 1 -1 1 -1 1 -1 -1 -1 -1 -1 1 1 -1 -1 1 -1 1 -1 1 1 1 1, zeros(1, 5)].';
    
    % Transmit LTF in both 10 MHz subchannels, apply tone rotation to upper channel
    ltf_f20 = [ltf_f10; 1j*ltf_f10];
    
    % Apply spectral shaping window
    ltf_f = ltf_f20(1:64*n_chan_temp).*kaiser(64*n_chan_temp, w_beta);
    
    % Base LTF waveform
    ltf_wf_base = 1/sqrt(52*n_chan_temp)*dot11_ifft(ltf_f, 64*n_chan_temp);
    
    % Append CP
    ltf_wf_20 = [ltf_wf_base(32*n_chan_temp+1:64*n_chan_temp); ltf_wf_base; ltf_wf_base];
end

% Select LTF based on 10 / 20 MHz channel
if (n_chan == 1)
    ltf_wf = ltf_wf_10;
elseif (n_chan == 2)
    ltf_wf = ltf_wf_20;
else
    error('not supported')
end

end
