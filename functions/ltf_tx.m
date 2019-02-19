function ltf_wf = ltf_tx(w_beta)
%LTF_TX Generates LTF preamble
%
%   Author: Ioannis Sarris, u-blox
%   email: ioannis.sarris@u-blox.com
%   August 2018; Last revision: 19-February-2019

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
persistent ltf_wf_base

if isempty(ltf_wf_base)
    % LTF f-domain represenation (including DC-subcarrier & guard bands)
    ltf_f = [zeros(1,6), 1 1 -1 -1 1 1 -1 1 -1 1 1 1 1 1 1 -1 -1 1 1 -1 1 -1 1 1 1 1 0 ...
        1 -1 -1 1 1 -1 1 -1 1 -1 -1 -1 -1 -1 1 1 -1 -1 1 -1 1 -1 1 1 1 1, zeros(1, 5)].';
    
    % Apply spectral shaping window
    ltf_f = ltf_f.*kaiser(64, w_beta);
    
    % Base LTF waveform
    ltf_wf_base = 1/sqrt(52)*dot11_ifft(ltf_f, 64);
end

% Append CP
ltf_wf = [ltf_wf_base(33:64); ltf_wf_base; ltf_wf_base];

end
