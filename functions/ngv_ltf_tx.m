function ngv_ltf_wf = ngv_ltf_tx(w_beta)
%NGV_LTF_TX Generates NGV-LTF preamble
%
%   Author: Ioannis Sarris, u-blox
%   email: ioannis.sarris@u-blox.com
%   July 2019; Last revision: 10-July-2019

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
persistent ngv_ltf_wf_base

if isempty(ngv_ltf_wf_base)
    % NGV-LTF f-domain represenation (including DC-subcarrier & guard bands)
    ngv_ltf_f = [zeros(1,4), 1 1 1 1 -1 -1 1 1 -1 1 -1 1 1 1 1 1 1 -1 -1 1 1 -1 1 -1 1 1 1 1 0 ...
        1 -1 -1 1 1 -1 1 -1 1 -1 -1 -1 -1 -1 1 1 -1 -1 1 -1 1 -1 1 1 1 1 1 1, zeros(1, 3)].';
    
    % Apply spectral shaping window
    ngv_ltf_f = ngv_ltf_f.*kaiser(64, w_beta);
    
    % Base LTF waveform
    ngv_ltf_wf_base = 1/sqrt(56)*dot11_ifft(ngv_ltf_f, 64);
end

% Append CP
ngv_ltf_wf = [ngv_ltf_wf_base(49:64); ngv_ltf_wf_base];

end
