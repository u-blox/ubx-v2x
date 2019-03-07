%BATCH_SIM - Batch simulation script
%   Top-level simulation script looping over MCS, SNR and Monte-Carlo iterations
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

%% Initialization
clc
clear all
close all

addpath('./functions;./mex')

% Set random number generator to specific seed
rand_stream = RandStream('mt19937ar', 'Seed', 0);
RandStream.setGlobalStream(rand_stream);

%% Simulation Parameters
% Simulation parameters
SIM.mcs_vec         = 0:7;      % Scalar or vector containing MCS values (0...7)
SIM.snr             = 0:.5:25;  % Scalar or vector containing SNR values (dB)
SIM.ovs             = 1;        % Oversampling factor
SIM.channel_model   = 0;        % Channel model (0: AWGN, 1-5: C2C models R-LOS, UA-LOS, C-NLOS, H-LOS and H-NLOS, 6-10: Enhanced C2C models R-LOS-ENH, UA-LOS-ENH, C-NLOS-ENH, H-LOS-ENH and H-NLOS-ENH)
SIM.use_mex         = false;    % Use MEX functions to accelerate simulation
SIM.n_iter          = 1000;     % Number of Monte-Carlo iterations
SIM.max_error       = 100;      % Number of packet errors before moving to next SNR point
SIM.min_error       = .005;     % Minimum PER target, beyond which, loop moves to next SNR point
SIM.check_sp        = false;    % Plot Tx spectrum and check for compliance
SIM.apply_cfo       = false;    % Apply CFO impairment on Tx and Rx

% Transmitter parameters
TX.payload_len      = 300;      % PHY payload length (bytes)
TX.window_en        = false;    % Apply time-domain windowing
TX.w_beta           = 0;        % Kaiser window beta coefficient for spectral shaping (0: disabled)
TX.pa_enable        = false;    % Apply PA non-linearity model
TX.pn_en            = false;    % Model Tx phase noise

% Receiver parameters
RX.pdet_thold       = 20;       % Packet detection threshold
RX.t_depth          = 2;        % Channel tracking time depth averaging (OFDM symbols)
RX.pn_en            = false;    % Model Rx phase noise

tic

%% Loop for MCS values
avgTHR = zeros(length(SIM.snr), length(SIM.mcs_vec));
for i_mcs = 1:length(SIM.mcs_vec)
    
    % Current MCS value
    TX.mcs = SIM.mcs_vec(i_mcs);
    
    % Initialize channel filter object
    chan_obj = chan_mod_init(SIM.channel_model, SIM.ovs);
    
    % Debugging message
    fprintf('\nChannel %i, MCS %i', SIM.channel_model, TX.mcs);
    
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
                [tx_wf, data_f_mtx, data_msg, PHY] = sim_tx_mex(TX.mcs, TX.payload_len, TX.window_en, TX.w_beta);
            else
                [tx_wf, data_f_mtx, data_msg, PHY] = sim_tx(TX.mcs, TX.payload_len, TX.window_en, TX.w_beta);
            end
            
            % Add CFO error, assume [-5, 5] ppm per Tx/Rx device
            if SIM.apply_cfo
                cfo_err = sum(rand(2, 1) - .5)*10e-6;
                tx_wf = apply_cfo(tx_wf, cfo_err);
            end
            
            % Apply Tx phase noise
            tx_wf = add_tx_pn(tx_wf, TX.pn_en);
            
            % Optional oversampling of the tranmitted waveform
            [tx_wf, ovs_filt_len] = upsample_tx(tx_wf, SIM.ovs);
            
            % Apply a memoryless nonlinearity model of the power amplifier
            tx_wf = pa_model(tx_wf, TX.pa_enable);
            
            % Evaluate the PSD and check for compliance
            check_sp_mask(tx_wf, ovs_filt_len, PHY.n_sym, SIM.ovs, SIM.check_sp);
            
            % Append silence samples at the beginning/end of useful waveform
            s0_len = randi([100 200]);
            tx_wf_full = [zeros(s0_len*SIM.ovs, 1); tx_wf; zeros((300 - s0_len)*SIM.ovs, 1)];
            
            % If channel model is defined, pass transmitted signal through channel filter
            if (SIM.channel_model == 0)
                rx_wf = tx_wf_full;
            else
                reset(chan_obj);
                rx_wf = step(chan_obj, tx_wf_full);
            end
            
            % Optional downsampling of the received waveform
            rx_wf = downsample_rx(rx_wf, SIM.ovs, ovs_filt_len);
            
            % Apply Rx phase noise
            rx_wf = add_rx_pn(rx_wf, RX.pn_en);
            
            % Add AWGN noise
            rx_wf = awgn(rx_wf, SIM.snr(i_snr));
            
            % Receiver model (MEX or M)
            if SIM.use_mex
                err = sim_rx_mex(PHY, rx_wf, s0_len, data_f_mtx, RX.t_depth, RX.pdet_thold);
            else
                err = sim_rx(PHY, rx_wf, s0_len, data_f_mtx, RX.t_depth, RX.pdet_thold);
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
    
    figure(SIM.channel_model + 1);
    
    % Plot PER
    subplot(1, 2, 1)
    semilogy(SIM.snr, avgPER, 'DisplayName', ['MCS' num2str(TX.mcs)]);
    drawnow; xlabel('SNR (dB)'); ylabel('PER');
    grid on; legend; hold on;
    
    % Plot throughput
    subplot(1, 2, 2)
    drate = 48.*PHY.n_dbps./PHY.n_cbps.*PHY.n_bpscs/8e-6*1e-6;
    avgTHR(:, i_mcs) = (1 - avgPER).*repmat(drate, size(avgPER, 1), 1);
    plot(SIM.snr, avgTHR(:, i_mcs), 'DisplayName', ['MCS' num2str(TX.mcs)]);
    drawnow; xlabel('SNR (dB)'); ylabel('Throughput (Mbps)');
    grid on; legend; hold on;
end

toc
