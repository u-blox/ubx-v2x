function [descr_msg] = data_rx(PHY, RX, rx_wf, idx0, h_est, data_f_mtx, r_cfo, snr_avg)
%DATA_RX Receiver processing of all DATA OFDM symbols
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

% Needed for code generation
coder.varsize('sym_out', [108 1], [1 0]);

% Size of the FFT
n_fft = PHY.n_chan*64;

% Number of samples in the cyclic prefix (CP)
cp_len = PHY.n_chan*16;

% Discard ofdm_off symbols from the end and replace them with the last ofdm_off symbols from the CP
ofdm_off = cp_len/2;

% idx0 points to the first sample of the CP
% idx points to the first sample that is used as input to the FFT
idx = idx0 + cp_len - ofdm_off;

% Number of receive antennas
n_rx = size(rx_wf, 2);

% Number of time-domain samples per OFDM symbol
n_sps = n_fft + cp_len;

% Calculate latency of (fake) channel tracking feedback
h_delay = ceil(96/PHY.n_dbps) + 1;

% Initialize matrix holding channel estimates for all OFDM symbols
h_est_mtx = complex(zeros(n_fft, PHY.n_sym + h_delay));

% Initialization based on PPDU format
if (PHY.ppdu_fmt == 1)
    % Midambles are disabled, fill initial buffer with channel estimate from LTF
    i_mid = 0;
    h_est_mtx(:, 1:h_delay*n_rx) = repmat(h_est, [1 h_delay]);
    sym_since_est = h_delay; % TODO: This will be used for CFO correction, verify this!
else
    % Initialize buffer with channel estimate from NGV-LTF
    i_mid = 1;
    h_est_mtx(:, 1:n_rx + n_rx*(i_mid-1)) = h_est;
    sym_since_est = 0;
end

% Loop for all OFDM symbols
data_bcc_vec = zeros(PHY.n_dbps, PHY.n_sym);
data_ldpc_vec = zeros(PHY.n_cbps, PHY.n_sym);
evm_mtx = zeros(PHY.n_sd, PHY.n_sym);

% Total samples for NGV-LTF
n_ngvltf_tot = PHY.n_ss * PHY.n_ngvltf_samp;

% Loop for all OFDM symbols
for i_sym = 1:PHY.n_sym
    % Track the number of symbols since the last channel estimate
    sym_since_est = sym_since_est + 1;
    
    % Check if midambles are enabled
    if ((PHY.mid > 0) && (i_sym > 1))
        
        % If this is a midamble symbol, perform channel estimation
        if (mod(i_sym, PHY.mid) == 1)
            % Increase counter of midamble symbols
            i_mid = i_mid + 1;
            
            % Reset the number of symbols since the last channel estimate
            sym_since_est = 1;
            
            % Channel estimation
            wf_in = rx_wf(idx:idx + n_ngvltf_tot - cp_len - 1,:);
            h_est = ngv_chan_est(wf_in, ofdm_off, PHY.n_ss, PHY.n_chan, PHY.n_ngvltf_samp);
            
            % Store channel estimate in a matrix
            h_est_mtx(:, (1:n_rx) + n_rx*(i_mid-1)) = h_est;
            
            % Go to next OFDM symbol for data processing
            idx = idx + n_ngvltf_tot;
        end
    end
    
    % Get waveform for current OFDM symbol
    wf_in = rx_wf(idx:idx + n_fft - 1, :);
    idx = idx + n_sps;
    
    % Find polarity sign for pilot subcarriers
    pol_sign = PHY.polarity_sign(mod(i_sym - 1 + PHY.pilot_offset, 127) + 1);
    
    % Perform FFT and MRC combinining
    y = complex(zeros(n_fft, n_rx));
    mrc_num = complex(zeros(PHY.n_sd,1));
    mrc_denom = complex(zeros(PHY.n_sd,1));
    
    % Loop for received antennas
    for i_rx = 1:n_rx
        
        % Perform FFT
        y(:, i_rx) = dot11_fft(wf_in([ofdm_off + 1:n_fft 1:ofdm_off], i_rx), n_fft)*sqrt(PHY.n_st)/n_fft;
        
        % If midamble is disabled, find (genie) channel estimate from received & transmitted waveforms
        % In real systems this comes from Data-Aided-Channel-Estimation processing
        if (PHY.mid == 0 && PHY.ppdu_fmt == 1)
            
            % Store current genie channel estimate for future use
            h_est_idx = i_rx + n_rx*(i_sym + h_delay - 1);
            h_est_mtx(:, h_est_idx) = y(:,i_rx)./data_f_mtx(:, i_sym);
            
            % Index of the most recent channel estimate that can be used (current symbol index minus decoding delay)
            curr_sym_idx = i_rx + n_rx*(i_sym - 1);
            
            % Index of the t_depth-th channel estimate before curr_sym_idx
            sym_idx0 = i_rx + n_rx*(max(1, i_sym - (RX.t_depth - 1)) - 1);
            
            % Time-average over the t_depth channel estimates
            h_est(:,i_rx) = mean(h_est_mtx(:, sym_idx0:n_rx:curr_sym_idx), 2);
        else
            % Get raw, unsmoothed estimate from most recent LTF or midamble
            h_est = h_est_mtx(:, (1:n_rx) + n_rx*(i_mid-1));
        end
        
        % Frequency-domain smoothing
        h_est = fd_smooth(h_est, PHY.n_sd);
        
        % Pilot values
        if (PHY.ppdu_fmt == 1)
            pilot_val = PHY.pilot_val;
        else
            % NGV pilot values are shifted by 1 for every symbol
            pilot_val = circshift(PHY.pilot_val, - (i_sym-1));
        end
        
        % Pilot CFO correction and equalization
        x_p = pol_sign*y(PHY.pilot_idx, i_rx)./h_est(PHY.pilot_idx, i_rx).*pilot_val*exp(-1j*r_cfo);
        
        % Residual CFO estimation
        r_cfo = (r_cfo + mean(angle(x_p)))/2;
        
        % MRC combining
        mrc_num = mrc_num + conj(h_est(PHY.data_idx, i_rx)).*y(PHY.data_idx, i_rx)*exp(-1j*r_cfo);
        mrc_denom = mrc_denom + abs(h_est(PHY.data_idx, i_rx)).^2;
    end
    sym_out = mrc_num./mrc_denom;
    
    % Channel gain per subcarrier
    gain_per_subcarrier = mrc_denom;
    
    % SNR per subcarrier for computing LLR values. Average SNR is limited in order to prevent ultra-large LLRs
    snr = gain_per_subcarrier * min(snr_avg, db2pow(26));
    
    % LLR demapping
    llr_in = llr_demap(sym_out.', PHY.n_bpscs, snr);
    
    % Deinterleaving
    x_data = deinterleaver(llr_in, PHY.n_bpscs, PHY.n_cbps, PHY.ppdu_fmt, PHY.n_chan);
    
    % Process through Viterbi decoder or store for LDPC processing
    if (PHY.ppdu_fmt == 1)
        % Store output binary data per OFDM symbol
        data_bcc_vec(:, i_sym) = bcc_dec(x_data', PHY.r_num, (i_sym == 1));
    else
        % Store data for LDPC processing
        data_ldpc_vec(:, i_sym) = x_data;
    end
    
    % EVM for debugging
    evm_mtx(:, i_sym) = abs(data_f_mtx(PHY.data_idx, i_sym) - sym_out).^2;
end

% Last pass of Viterbi or LDPC decoder
if (PHY.ppdu_fmt == 1)
    % Last pass of Viterbi decoder
    bits_out = bcc_dec(zeros(96*2, 1), PHY.r_num, false);
    data_out = [data_bcc_vec(:); bits_out];
    
    % Descrambling
    descr_msg = descrambler_rx(logical(data_out(97:end)));
else
    data_out = ldpc_dec(PHY.LDPC, [data_ldpc_vec(:); zeros(PHY.n_cbps,1)], RX.ldpc_cfg);
    
    % Descrambling
    descr_msg = descrambler_rx(logical(data_out));
end

end
