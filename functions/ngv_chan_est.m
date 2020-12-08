function h_est = ngv_chan_est(r, ofdm_off, n_ss, n_chan, n_nltf_samples)
%NGV_CHAN_EST Channel estimation algorithm, using NGV-LTF preamble
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

% NGV-LTF f-domain representation
ltf_left = [1 1 -1 -1 1 1 -1 1 -1 1 1 1 1 1 1 -1 -1 1 1 -1 1 -1 1 1 1 1].';
ltf_right = [1 -1 -1 1 1 -1 1 -1 1 -1 -1 -1 -1 -1 1 1 -1 -1 1  -1 1 -1 1 1 1 1].';

if (n_chan == 1)
    n_fft = 64;
    n_st = 56;
    ngv_ltf_f = [zeros(4,1); 1; 1; ltf_left; 0; ltf_right; -1; -1; zeros(3,1);];
else
    n_fft = 128;
    n_st = 114;
    ngv_ltf_f = complex([zeros(6,1); ltf_left; 1; ltf_right; -1; -1; -1; 1; zeros(3,1); -1; 1; 1; -1; ltf_left; 1; ltf_right; zeros(5,1)]);
    
    % Apply tone rotation for 20 MHz waveform: subcarriers k>=0 are multiplied by j
    ngv_ltf_f(65:128) = ngv_ltf_f(65:128) * 1j;
end

% Number of receive chains
n_rx = size(r,2);
h_est = complex(zeros(64*n_chan, size(r,2)));
for i_rx = 1:n_rx
    if (n_nltf_samples == 48*n_chan)
        % Compressed NGV-LTF-1x. Repeat the received waveform twice
        y = dot11_fft([r([ofdm_off+1:n_fft/2 1:ofdm_off], i_rx); r([ofdm_off+1:n_fft/2 1:ofdm_off], i_rx)], n_fft)*sqrt(n_st)/n_fft;
        % Least-Squares channel estimation for the even-numbered subcarriers
        h_est(:,i_rx) = y./ngv_ltf_f;
        if (n_chan == 1)
            h_est(33,i_rx) = (h_est(31,i_rx) + h_est(35,i_rx))/2;
        else
            h_est(65,i_rx) = (h_est(63,i_rx) + h_est(67,i_rx))/2;
        end
        % Interpolate the channel estimates for the missing odd-numbered subcarriers
        h_est(isnan(h_est) | isinf(h_est)) = 0;
        h_est(:,i_rx) = interp1(1:2:n_fft, h_est(1:2:n_fft, i_rx), 1:n_fft, 'pchip');
        
        % Set the channel estimates for unused subcarriers to zero
        h_est(ngv_ltf_f==0, i_rx) = 0;
    else
        % Default NGV-LTF-2x format or NGV-LTF-repeat format
        if (n_nltf_samples == 144*n_chan)
            %try simple time-domain combining
            r(1:n_fft,i_rx) = r(1:n_fft,i_rx) + r(n_fft+1:2*n_fft,i_rx);
        end
        
        % FFT on the time-domain sequence
        y = dot11_fft(r([ofdm_off+1:n_fft 1:ofdm_off], i_rx), n_fft)*sqrt(n_st)/n_fft;
        % Least-Squares channel estimation
        h_est(:, i_rx) = y./ngv_ltf_f;
    end
end


end
