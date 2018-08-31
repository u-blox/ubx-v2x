%BATCH_SIM - Batch simulation script
%   Top-level simulation script looping over MCS, SNR and Monte-Carlo iterations
%
%   Author: Ioannis Sarris, u-blox
%   email: ioannis.sarris@u-blox.com
%   August 2018; Last revision: 30-August-2018

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

%% Initialization
clc
clear
close all

addpath('./functions;./mex')

% Set random number generator to specific seed
rand_stream = RandStream('mt19937ar', 'Seed', 0);
RandStream.setGlobalStream(rand_stream);

%% Simulation Parameters
% Transceiver parameters
SIM.mcs_vec         = 0:7;      % Scalar or vector containing MCS values (0...7)
SIM.payload_len     = 300;      % PHY payload length (bytes)
SIM.pdet_thold      = 20;       % Packet detection threshold
SIM.h_delay         = 3;        % Channel tracking delay (OFDM symbols)
SIM.t_depth         = 2;        % Channel tracking time depth averaging (OFDM symbols)

% Simulation settings
SIM.use_mex         = false;    % Use MEX functions to accelerate simulation
SIM.n_iter          = 1000;     % Number of Monte-Carlo iterations
SIM.max_error       = 100;      % Number of packet errors before moving to next SNR point
SIM.min_error       = .005;     % Minimum PER target, beyond which, loop moves to next SNR point

% Channel model settings
SIM.channel_model   = 0;        % Channel model (0: AWGN, 1-5: C2C models R-LOS, UA-LOS, C-NLOS, H-LOS or H-NLOS)
SIM.snr             = 0:.5:25;  % Scalar or vector containing SNR values (dB)

tic

%% Loop for MCS values
for i_mcs = 1:length(SIM.mcs_vec)
    
    % Current MCS value
    SIM.mcs = SIM.mcs_vec(i_mcs);
    
    % Initialize channel filter object
    chan_obj = chan_mod_init(SIM.channel_model);
    
    % Debugging message
    fprintf('\nChannel %i, MCS %i', SIM.channel_model, SIM.mcs);
    
    %% Loop for SNR values
    BER = zeros(length(SIM.snr), SIM.n_iter);
    PER = zeros(length(SIM.snr), SIM.n_iter);
    avgPER = zeros(length(SIM.snr), 1);
    for i_snr = 1:length(SIM.snr)
        
        % Number of packer errors at the current SNR level
        sum_error = 0;
        
        % Debugging message
        fprintf('\nSNR: %02.1f dB ', SIM.snr(i_snr))
        
        %% Loop for Monte-Carlo iterations
        for i_iter = 1:SIM.n_iter
            
            % Fix random seed to allow reproduceability
            reset(rand_stream, i_iter);
            
            % Transmitter model (MEX or M)
            if SIM.use_mex
                [tx_wf, data_f_mtx, data_msg, PHY] = sim_tx_mex(SIM.mcs, SIM.payload_len);
            else
                [tx_wf, data_f_mtx, data_msg, PHY] = sim_tx(SIM.mcs, SIM.payload_len);
            end
            
            % Append silence samples at the beginning/end of useful waveform
            s0_len = randi([100 200]);
            tx_wf_full = [zeros(s0_len, 1); tx_wf; zeros(100, 1)];
            
            % If channel model is defined, pass transmitted signal through channel filter
            if (SIM.channel_model == 0)
                rx_wf = tx_wf_full;
            else
                reset(chan_obj);
                rx_wf = step(chan_obj, tx_wf_full);
            end

            % Add AWGN noise
            rx_wf = awgn(rx_wf, SIM.snr(i_snr));
            
            % Receiver model (MEX or M)
            if SIM.use_mex
                err = sim_rx_mex(PHY, rx_wf, s0_len, data_f_mtx, SIM.h_delay, SIM.t_depth, SIM.pdet_thold);
            else
                err = sim_rx(PHY, rx_wf, s0_len, data_f_mtx, SIM.h_delay, SIM.t_depth, SIM.pdet_thold);
            end
            
            % Display debugging information
            switch err
                case 0
                    fprintf('.'); % No error
                case 1
                    fprintf('x'); % Packet detection error
                case 2
                    fprintf('o'); % SIG error
                case 3
                    fprintf('!'); % DATA error
            end
            
            % Store PER in array
            PER(i_snr, i_iter) = (err > 0);
            
            % Update sum of PER
            sum_error = sum_error + PER(i_snr, i_iter);
            
            % Check if number of errors exceeds target
            avgPER(i_snr) = mean(PER(i_snr, 1:i_iter));
            if (sum_error >= SIM.max_error)
                break
            end
            
            pause(.001);
        end
        
        % If PER drops below min_error, break SNR loop
        if (sum_error/i_iter < SIM.min_error)
            break
        end
    end
    
    % Plot PER
    figure(SIM.channel_model + 1);
    semilogy(SIM.snr, avgPER, 'DisplayName', ['MCS' num2str(SIM.mcs)]);
    drawnow; xlabel('SNR (dB)'); ylabel('PER');
    grid on; legend; hold on;
end

toc
