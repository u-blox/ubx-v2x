function [out, filt_len] = upsample_tx(in, ovs)
%UPSAMPLE_TX Oversample transmitted signal by an integer factor
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

% Apply oversampling if factor > 1
if (ovs > 1)
    % Filter length and attenuation factor for Chebyshev window (dB)
    filt_len = 128;
    r = 50;
    
    % Generate filter coefficients
    coeffs = ovs.*firnyquist(filt_len, ovs, chebwin(filt_len + 1, r));
    
    % Apply filter, removing trailing zeros from coefficients
    i_filt = dsp.FIRInterpolator(ovs, 'Numerator', coeffs(1:end-1));
    out = i_filt([in; zeros(filt_len/2, 1)]);
else
    out = in;
    filt_len = 0;
end

end
