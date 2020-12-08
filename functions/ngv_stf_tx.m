function ngv_stf_wf = ngv_stf_tx(w_beta, n_chan)
%NGV_STF_TX Generates NGV-STF preamble
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
persistent ngv_stf_wf10 ngv_stf_wf20

if isempty(ngv_stf_wf10) || isempty(ngv_stf_wf20)
    % NGV-STF f-domain representation
    stf_sp10_base = sqrt(1/2)*[0 0 1+1j 0 0 0 -1-1j 0 0 0 1+1j 0 0 0 -1-1j 0 0 0 -1-1j 0 0 0 1+1j 0 0 0 ...
        0 0 0 0 -1-1j 0 0 0 -1-1j 0 0 0 1+1j 0 0 0 1+1j 0 0 0 1+1j 0 0 0 1+1j 0 0].';
    
    % Full NGV-STF spectrum without phase rotation
    ngv_stf_f10 = [zeros(6,1); stf_sp10_base; zeros(5,1)];
    ngv_stf_f20 = complex([zeros(6,1); stf_sp10_base; zeros(11, 1); stf_sp10_base; zeros(5,1)]);
    
    % Apply tone rotation for 20 MHz waveform: subcarriers k>=0 are multiplied by j
    ngv_stf_f20(65:128) = ngv_stf_f20(65:128) * 1j;
    
    % Apply spectral shaping window
    ngv_stf_f10 = ngv_stf_f10.*kaiser(64, w_beta);
    ngv_stf_f20 = ngv_stf_f20.*kaiser(128, w_beta);
    
    % Base STF waveform
    ngv_stf_wf10_base = 1/sqrt(12)*dot11_ifft(ngv_stf_f10, 64);
    ngv_stf_wf20_base = 1/sqrt(12)*dot11_ifft(ngv_stf_f20, 128);
    
    % Append CP
    ngv_stf_wf10 = [ngv_stf_wf10_base(49:64); ngv_stf_wf10_base];
    ngv_stf_wf20 = [ngv_stf_wf20_base(97:128); ngv_stf_wf20_base];
end

if (n_chan == 1)
    ngv_stf_wf = ngv_stf_wf10;
elseif (n_chan == 2)
    ngv_stf_wf = ngv_stf_wf20;
else
    error('n_chan not supported')
end

end
