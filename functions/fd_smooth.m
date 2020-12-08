function h_out = fd_smooth(h_in, n_sd)
%FD_SMOOTH Frequency-domain smoothing
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

% Number of guard subcarriers
n_fft = size(h_in, 1);
n_rx = size(h_in, 2);

% 10 MHz mode
if (n_fft == 64)
    
    k = 6;
    if (n_sd == 52)
        k = 4;
    end
    
    % Replicate missing values to enable smoothing
    h_in(1:k, :) = h_in((k + 1)*ones(1, k), :);
    h_in(33, :) = (h_in(32, :) + h_in(34, :))/2;
    h_in((n_fft+2 - k):n_fft, :) = h_in((n_fft+1 - k)*ones(1, k - 1), :);
    
    % Moving-average smoothing
    h_out = complex(zeros(n_fft, n_rx));
    
    % Apply length-3 window
    h_out(2:n_fft-1, :) = h_in(1:n_fft-2, :)*.15 + h_in(2:n_fft-1, :)*.7 + h_in(3:n_fft, :)*.15;
else
    % 20 MHz mode
    
    % Replicate missing values to enable smoothing
    if (n_sd == 48)
        % 10 MHz legacy SIG or data fields, possibly in both subchannels
        h_in(60, :) = h_in(59, :);
        h_in(70, :) = h_in(71, :);
        h_in(61:69, :) = 0;
        k = 6;
    elseif (n_sd == 52)
        % 10 MHz NGV waveform received while in 20 MHz reception mode
        h_in(62, :) = h_in(61, :);
        h_in(68, :) = h_in(69, :);
        h_in(62:68, :) = 0;
        k = 4;
    else
        % 20 MHz NGV waveform
        h_in(65, :) = (h_in(63, :) + h_in(67, :))/2;
        h_in(64, :) = (h_in(63, :) + h_in(65, :))/2;
        h_in(66, :) = (h_in(65, :) + h_in(67, :))/2;
        k = 6;
    end
    h_in(97, :) = (h_in(96, :) + h_in(98, :))/2;
    
    h_in(1:k, :) = h_in((k + 1)*ones(1, k), :);
    h_in(33, :) = (h_in(32, :) + h_in(34, :))/2;
    h_in((n_fft + 2 - k):n_fft, :) = h_in((n_fft + 1 - k)*ones(1, k - 1), :);
    
    % Moving-average smoothing
    h_out = complex(zeros(n_fft, n_rx));
    
    % Apply length-3 window
    h_out(2:n_fft - 1, :) = h_in(1:n_fft - 2, :)*.15 + h_in(2:n_fft - 1, :)*.7 + h_in(3:n_fft, :)*.15;
end

end