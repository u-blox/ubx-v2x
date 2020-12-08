function ngv_ltf_wf = ngv_ltf_tx(w_beta, n_chan, n_ss, ltf_fmt)
%NGV_LTF_TX Generates NGV-LTF preamble
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
persistent ngv_ltf10_wf_base
persistent ngv_ltf10_comp_wf_base
persistent ngv_ltf20_wf_base
persistent ngv_ltf20_comp_wf_base


if isempty(ngv_ltf10_wf_base) || isempty(ngv_ltf10_comp_wf_base) || isempty(ngv_ltf20_wf_base) || isempty(ngv_ltf20_comp_wf_base)
    % NGV-LTF f-domain representation
    ltf_left = [1 1 -1 -1 1 1 -1 1 -1 1 1 1 1 1 1 -1 -1 1 1 -1 1 -1 1 1 1 1].';
    ltf_right = [1 -1 -1 1 1 -1 1 -1 1 -1 -1 -1 -1 -1 1 1 -1 -1 1  -1 1 -1 1 1 1 1].';
    
    % Full NGV-LTF spectrum without phase rotation
    ngv_ltf10_f = [zeros(4,1); 1; 1; ltf_left; 0; ltf_right; -1; -1; zeros(3,1);];
    ngv_ltf20_f = complex([zeros(6,1); ltf_left; 1; ltf_right; -1; -1; -1; 1; zeros(3,1); -1; 1; 1; -1; ltf_left; 1; ltf_right; zeros(5,1)]);
    
    % Apply tone rotation for 20 MHz waveform: subcarriers k>=0 are multiplied by j
    ngv_ltf20_f(65:128) = ngv_ltf20_f(65:128) * 1j;
    
    % Apply spectral shaping window
    ngv_ltf10_f = ngv_ltf10_f.*kaiser(64, w_beta);
    ngv_ltf20_f = ngv_ltf20_f.*kaiser(128, w_beta);
    
    % Compressed NGV-LTF-1x waveforms: Every other subcarrier is 0
    ngv_ltf10_f_comp = ngv_ltf10_f(1:2:end);
    ngv_ltf20_f_comp = ngv_ltf20_f(1:2:end);
    
    % Base LTF waveform
    ngv_ltf10_wf_base = 1/sqrt(56)*dot11_ifft(ngv_ltf10_f, 64);
    ngv_ltf20_wf_base = 1/sqrt(114)*dot11_ifft(ngv_ltf20_f, 128);
    
    % Compressed LTF waveform
    ngv_ltf10_comp_wf_base = 1/sqrt(56)*dot11_ifft(ngv_ltf10_f_comp, 32);
    ngv_ltf20_comp_wf_base = 1/sqrt(114)*dot11_ifft(ngv_ltf20_f_comp, 64);
end


% Append CP and return
if (n_ss == 1)
    % One spatial stream
    if (n_chan == 1)
        if (ltf_fmt == 0)
            ngv_ltf_wf = [ngv_ltf10_wf_base(49:64); ngv_ltf10_wf_base];
        elseif (ltf_fmt == 1)
            ngv_ltf_wf = [ngv_ltf10_comp_wf_base(17:32); ngv_ltf10_comp_wf_base];
        elseif (ltf_fmt == 2)
            ngv_ltf_wf = [ngv_ltf10_wf_base(49:64); ngv_ltf10_wf_base; ngv_ltf10_wf_base];
        else
            error('ltf_fmt not supported')
        end
    elseif (n_chan == 2)
        if (ltf_fmt == 0)
            ngv_ltf_wf = [ngv_ltf20_wf_base(97:128); ngv_ltf20_wf_base];
        elseif (ltf_fmt == 1)
            ngv_ltf_wf = [ngv_ltf20_comp_wf_base(33:64); ngv_ltf20_comp_wf_base];
        elseif (ltf_fmt == 2)
            ngv_ltf_wf = [ngv_ltf20_wf_base(97:128); ngv_ltf20_wf_base; ngv_ltf20_wf_base];
        else
            error('ltf_fmt not supported')
        end
    else
        error('n_chan not supported')
    end
else
    % TODO: Implement support for multiple NGV-LTFs for MIMO
    error('Multiple NGV-LTF transmission for MIMO is not yet supported')
end
end
