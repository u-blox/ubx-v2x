%BATCH_SIM - Batch simulation script
%   Top-level simulation script looping over MCS, SNR and Monte-Carlo iterations
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

%% Initialization
clc
clear all
close all

addpath('./functions;./ext;./mex')

% Set random number generator to specific seed
rand_stream = RandStream('mt19937ar', 'Seed', 0);
RandStream.setGlobalStream(rand_stream);

%% Simulation Parameters
% General parameters
SIM.mcs_vec         = 0:10;     % Scalar or vector containing MCS values (0...10)
SIM.snr             = -5:5:35;    % Scalar or vector containing SNR values (dB)
SIM.ovs             = 1;        % Oversampling factor
SIM.channel_model   = 1;        % Channel model (0: AWGN, 1-5: C2C models R-LOS, UA-LOS, C-NLOS, H-LOS and H-NLOS, 6-10: Enhanced C2C models R-LOS-ENH, UA-LOS-ENH, C-NLOS-ENH, H-LOS-ENH and H-NLOS-ENH)
SIM.use_mex         = false;    % Use MEX functions to accelerate simulation
SIM.n_iter          = 30;     	% Number of Monte-Carlo iterations
SIM.max_error       = 100;      % Number of packet errors before moving to next SNR point
SIM.min_error       = .005;     % Minimum PER target, beyond which, loop moves to next SNR point
SIM.check_sp        = false;    % Plot Tx spectrum and check for compliance
SIM.apply_cfo       = false;    % Apply CFO impairment on Tx and Rx

% Transmitter parameters
TX.payload_len      = 350;      % MPDU_LENGTH / PHY payload length (bytes) (without A-MPDU header and without MAC padding)
TX.window_en        = false;    % Apply time-domain windowing
TX.w_beta           = 0;        % Kaiser window beta coefficient for spectral shaping (use "0" for disabling this filter)
TX.pa_enable        = false;    % Apply PA non-linearity model
TX.pn_en            = false;    % Model Tx phase noise
TX.bw_mhz           = 10;       % Bandwidth (10 or 20 MHz)

% Candidate NGV features
TX.ppdu_fmt         = 2;        % PPDU format (1: Legacy, 2: NGV)
TX.mid              = 4;        % NGV only: midamble period 4/8/16 symbols
TX.n_ss             = 1;        % NGV only: Number of MIMO spatial streams (1..2), 2 is not yet supported
TX.ltf_fmt_init     = 0;        % NGV only: LTF format for MCS 0-9. (0: NGV-LTF-2x (8 us, default), 1: compressed NGV-LTF-1x (4.8 us))
% Note: MCS 10 always uses LTF format 2, NGV-LTF-repeat (14.4 us), but this will be set automatically
TX.n_tx_ant         = 1;        % Number of transmit antennas

% Receiver parameters
RX.n_rx_ant         = 1;        % Number of receive antennas
RX.bw_mhz           = TX.bw_mhz; % Bandwidth of the received waveform
RX.pdet_thold_def   = 20;       % Packet detection threshold
RX.t_depth          = 2;        % Channel tracking time depth averaging (OFDM symbols)
RX.pn_en            = false;    % Model Rx phase noise
RX.ldpc_cfg.iter    = 50;       % Number of iterations
RX.ldpc_cfg.minsum  = 1;        % Only for external decoder 0: Sum-product (gives .5 - 1dB gain) 1: min-sum algorithm

error_char_vec = '.xo!uhnf!'; % For printing receiver message decoding results
% 0 => .   no error
% 1 => x   pdet error
% 2 => o   SIG error
% 3 => !   data decoding error
% 4 => u   undetected PHY parameter error (SIG/NGV-SIG)
% 5 => h   heuristic error
% 6 => n   NGV-SIG error
% 7 => f   format / autodetection error (NGV and legacy formats confused)
% 8 => !   A-MPDU header error (part of the data field)

ppdu_descriptor = {'p', 'bd'};

tic

if (TX.ppdu_fmt == 1 && TX.bw_mhz == 20)
    disp('Warning: non-usual 20 MHz transmissions with 802.11p (4 us symbols, 0.8 us GI, 312.5 kHz subcarrier spacing)')
    % Same PHY format as regular 802.11a 20 MHz. There is only a single 20 MHz wide (sub-)channel
    TX.n_chan = 1;
    RX.n_chan = 1;
else
    % Default for regular 10 MHz 802.11p and for 10/20 MHz 802.11bd, with 156 kHz subcarrier spacing
    % The number of adjacent subchannels (1 or 2) is determined by the bandwidth (10 or 20)
    % TX and RX may be different (Receiver in 20 MHz mode must also decode a 10 MHz PPDU in one subchannel)
    TX.n_chan = TX.bw_mhz/10;
    RX.n_chan = RX.bw_mhz/10;
end

% Check if midamble peridocity setting is valid
if (TX.ppdu_fmt == 1)
    TX.mid = 0;
else
    if ( ~any(TX.mid == [4 8 16]) )
        error('802.11bd Midamble periodicity (M) should be 4, 8, or 16')
    end
end

%% Loop for MCS values
avgTHR = zeros(length(SIM.snr), length(SIM.mcs_vec));
for i_mcs = 1:length(SIM.mcs_vec)
    
    % Current MCS value
    TX.mcs = SIM.mcs_vec(i_mcs);
    if (TX.ppdu_fmt == 1  && TX.mcs > 7 ) ...
            || (TX.ppdu_fmt == 2  && TX.mcs == 9 && TX.bw_mhz == 10 )
        % MCS not supported
        continue
    end
    
    if (TX.ppdu_fmt == 2 && (TX.mcs == 0 || TX.mcs == 10))
        % MCS 0 (BPSK) and MCS 10 (BPSK-DCM) require a 3 dB power boost for STF and LTF
        % The packet detection does not yet implement gain control based on STF/LTF power and does not work properly
        % Workaround: Increase RX pdet threshold to compensate for power boost
        RX.pdet_thold = RX.pdet_thold_def*sqrt(2);
        % TODO: Implement more realistic pdet and remove this workaround
    else
        RX.pdet_thold = RX.pdet_thold_def;
    end
    
    % Initialize channel filter object
    [chan_obj, chan_name] = chan_mod_init(SIM.channel_model, RX.bw_mhz, SIM.ovs, TX.n_tx_ant, RX.n_rx_ant);
    
    % Debugging message
    PHY0 = tx_phy_params('TX', TX.mcs, TX.payload_len, TX.ppdu_fmt, TX.mid, TX.n_ss, TX.ltf_fmt_init, TX.n_chan, 0, 0);
    fprintf('\nChannel %i (%s), %s-MCS %i (%s R=%d/%d), %d MHz, M=%d, %dx%d ant', SIM.channel_model, chan_name, ppdu_descriptor{TX.ppdu_fmt}, TX.mcs, n_bpscs_to_string(PHY0.n_bpscs),PHY0.r_num,PHY0.r_denom, TX.bw_mhz, TX.mid, TX.n_tx_ant, RX.n_rx_ant);
    
    %% Loop for SNR values
    avgPER = zeros(length(SIM.snr), 1);
    for i_snr = 1:length(SIM.snr)
        % Total number of transmissions at the current SNR level
        sum_trials = 0;
        % Number of packer errors at the current SNR level
        sum_error = 0;
        
        % Debugging message
        fprintf('\nSNR: %4.1f dB ', SIM.snr(i_snr))
        
        %% Loop for Monte-Carlo iterations
        for i_iter = 1:SIM.n_iter
            % Fix random seed to allow reproduceability
            rand_seed = i_iter;
            reset(rand_stream, rand_seed);
            
            % Transmitter model (MEX or M)
            if SIM.use_mex
                [tx_wf, data_f_mtx, data_msg, PHY] = sim_tx_mex(TX);
            else
                [tx_wf, data_f_mtx, data_msg, PHY] = sim_tx(TX);
            end
            
            % Add CFO error, assume [-5, 5] ppm per Tx/Rx device
            if SIM.apply_cfo
                cfo_err = sum(rand(2, 1) - .5)*10e-6;
                tx_wf = apply_cfo(tx_wf, cfo_err);
            else
                cfo_err = 0;
            end
            
            % Apply Tx phase noise
            tx_wf = add_tx_pn(tx_wf, TX.pn_en);
            
            % Mandatory 2x upsampling and frequency shift if transmitting a 10 MHz signal in 20 MHz receive mode
            % TODO: numerous adaptions at the receiver (in pdet, fine_sync, ...) to support this
            if (RX.bw_mhz == 20 && TX.bw_mhz == 10)
                [tx_wf, ovs_filt_len1] = upsample_tx(tx_wf, 2);
                % Shift into lower 10 MHz subchannel
                tx_wf = tx_wf .* exp(-1j*2*pi*(1:length(tx_wf))/128*32).';
            end
            
            % Optional oversampling of the tranmitted waveform
            [tx_wf, ovs_filt_len] = upsample_tx(tx_wf, SIM.ovs);
            
            % Apply a memoryless nonlinearity model of the power amplifier
            tx_wf = pa_model(tx_wf, TX.pa_enable);
            
            % Evaluate the PSD and check for compliance
            check_sp_mask(tx_wf, ovs_filt_len, PHY.n_sym, SIM.ovs, SIM.check_sp);
            
            % Append silence samples at the beginning/end of useful waveform
            s0_len = randi([100 200]);
            tx_wf_full = [zeros(s0_len*SIM.ovs, TX.n_tx_ant); tx_wf; zeros((400 - s0_len)*SIM.ovs, TX.n_tx_ant)];
            
            % If channel model is defined, pass transmitted signal through channel filter
            if (SIM.channel_model == 0)
                % Enable multi-antenna modes for AWGN channel
                if TX.n_tx_ant == 2 && RX.n_rx_ant > 1
                    vec2 = [1 -1 1 1 ]; % entry i denotes the channel from TX antenna 2 to receive antenna i
                    rx_wf = repmat(tx_wf_full(:,1), 1, RX.n_rx_ant) + repmat(tx_wf_full(:,2), 1, RX.n_rx_ant).*vec2(1:RX.n_rx_ant);
                else
                    rx_wf = repmat(tx_wf_full, 1, RX.n_rx_ant);
                end
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
                err = sim_rx_mex(rx_wf, data_f_mtx, RX, TX, s0_len);
            else
                err = sim_rx(rx_wf, data_f_mtx, RX, TX, s0_len);
            end
            
            % Update sum of PER
            sum_error = sum_error + (err > 0);
            sum_trials = sum_trials + 1;
            
            % Print error status character
            error_status = error_char_vec(err+1);
            fprintf(error_status);
            % Check if number of errors exceeds target
            if (sum_error >= SIM.max_error)
                break
            end
            
            pause(.001);
        end
        
        avgPER(i_snr) = sum_error/sum_trials;
        
        % If PER drops below min_error, break SNR loop
        if (sum_error/sum_trials < SIM.min_error)
            break
        end
    end
    fprintf('\n')
    
    % Find throughput efficiency factor (affected by midamble periodicity and duration of the midamble symbols, which is 8, 4.8 or 14.4 us)
    if (TX.mid == 0)
        eff = 1;
    else
        eff = (TX.mid*8)/(TX.mid*8 + PHY0.n_ss * PHY0.t_ngvltf);
    end
    % Goodput calculation
    drate = eff*PHY0.n_sd*PHY0.n_dbps./PHY0.n_cbps.*PHY0.n_bpscs/8e-6*1e-6;
    avgTHR(:, i_mcs) = (1 - avgPER).*repmat(drate, size(avgPER, 1), 1);
    
    figure(SIM.channel_model + 1);
    % Plot PER
    subplot(1, 2, 1)
    title(sprintf('\nChannel %i (%s), M=%d', SIM.channel_model, chan_name, TX.mid));
    legend_string = sprintf('%s-MCS-%i (%s %d/%d)', ppdu_descriptor{TX.ppdu_fmt}, TX.mcs, n_bpscs_to_string(PHY0.n_bpscs),PHY0.r_num,PHY0.r_denom);
    semilogy(SIM.snr, avgPER, 'DisplayName', legend_string, 'LineWidth', 1.5);
    drawnow; xlabel('SNR (dB)'); ylabel('PER');
    grid on; legend('Location', 'SouthWest'); hold on;
    
    % Plot throughput
    subplot(1, 2, 2)
    title(sprintf('\nChannel %i (%s), M=%d', SIM.channel_model, chan_name, TX.mid));
    plot(SIM.snr, avgTHR(:, i_mcs), 'DisplayName', legend_string, 'LineWidth', 1.5);
    drawnow; xlabel('SNR (dB)'); ylabel('Throughput (Mbps)');
    grid on; legend('Location', 'NorthWest'); hold on;
end

% Plot overall throughput
plot(SIM.snr, max(avgTHR, [], 2), 'k', 'DisplayName', 'Overall', 'LineWidth', 2);

toc
