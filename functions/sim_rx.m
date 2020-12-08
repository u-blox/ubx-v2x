function [err] = sim_rx(rx_wf, data_f_mtx, RX, TX, s0_len)
%SIM_RX High-level receiver function
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
coder.varsize('rx_out', [8*4096 1], [1 0]);

% SIG data/pilot subcarrier indices
sig_data_idx = [-26:-22 -20:-8 -6:-1 1:6 8:20 22:26].' + 33;
sig_pilot_idx = [-21 -7 7 21].' + 33;

% Indicate the number of 10 MHz channels on which the receiver operates (1: single 10 MHz channel, 2: two adjacacent 10 MHz channels for 20 MHz reception)
% Used to set the FFT size (64*n_chan_rx) and the number of time-domain samples per OFDM symbol (80*n_chan_rx)
% Note: The non-common 20 MHz 802.11p requires n_chan_rx=1
n_chan_rx = RX.n_chan;

% Packet detection / coarse CFO estimation
[c_idx, c_cfo, pdet_err] = pdet(rx_wf, s0_len, RX.pdet_thold, n_chan_rx);

% If no packet error, proceed with packet decoding
err = 0;
if pdet_err
    err = 1;
else
    % Coarse CFO correction
    rx_wf = apply_cfo(rx_wf, -c_cfo/5.9e9*10e6);
    
    % Fine synchronization / fine CFO estimation based on L-LTF
    [f_idx, f_cfo] = fine_sync(rx_wf, c_idx, n_chan_rx);
    
    % Fine CFO correction
    rx_wf = apply_cfo(rx_wf, -f_cfo/5.9e9*10e6);
    
    % Channel estimation based on L-LTF
    wf_in_ltf = rx_wf(f_idx:f_idx + 128*n_chan_rx-1,:);
    h_est = chan_est(wf_in_ltf, n_chan_rx);
    % f_idx is 24/48 symbols into L-LTF (8/16 symbols before the end of the CP)
    % From now on, idx0 always points to the first sample of the CP in each OFDM symbol
    % This provides more flexibility, e.g. for different NGV-LTF formats
    idx0 = f_idx + 128*n_chan_rx + 8*n_chan_rx;
    
    % Keep track of the number of symbols since the last channel estimate
    sym_since_est = 1;
    
    % SNR estimation
    i_rx = 1;
    % TODO: estimate SNR also for multiple RX chains
    % TODO: estimate SNR individually for each 10 MHz subchannel
    snr_avg = 2/(mean(abs(wf_in_ltf(1:64*n_chan_rx,i_rx) - wf_in_ltf(64*n_chan_rx+1:128*n_chan_rx,i_rx)).^2));
    
    % Initial L-SIG reception
    wf_in = rx_wf(idx0:idx0 + 80*n_chan_rx-1,:);
    prev_cfo_corr = 0;
    new_cfo_weight = 0; % 0: disable CFO correction for L-SIG
    [x_p0, x_d0_cfo, snr0, r_phase_diff0, llr_lsig] = sig_pre_rx(wf_in, h_est, sig_data_idx, sig_pilot_idx, n_chan_rx, prev_cfo_corr, new_cfo_weight);
    r_cfo = r_phase_diff0 * new_cfo_weight;
    L_SIG_CFG = sig_rx(x_d0_cfo, snr0);
    idx0 = idx0 + 80*n_chan_rx;
    sym_since_est = 2;
    
    % Check for RL-SIG
    wf_in = rx_wf(idx0:idx0 + 80*n_chan_rx-1,:);
    prev_cfo_corr = r_cfo * sym_since_est;
    new_cfo_weight = 0; % 0: disable CFO correction for RL-SIG
    [x_p1, x_d1_cfo, snr1, r_phase_diff1, llr_rlsig] = sig_pre_rx(wf_in, h_est, sig_data_idx, sig_pilot_idx, n_chan_rx, prev_cfo_corr, new_cfo_weight);
    r_cfo = (r_cfo * sym_since_est + new_cfo_weight *  r_phase_diff1) / sym_since_est;
    idx0 = idx0 + 80*n_chan_rx;
    sym_since_est = 3;
    
    % Correlation estimation L-SIG -- RL-SIG
    % Use correlation of the signs of the demodulated values (directly related to the Hamming distance (hd))
    sig_cor_hd = sign(real([x_d0_cfo]))'*sign(real([x_d1_cfo]));
    
    % For best performance, correlation threshold should depend on the received SNR (still WIP)
    autodet.thr_vec  = [14 16 18 22];
    autodet.snr_vec  = [-100, 2, 5, 8];
    
    threshold = interp1(autodet.snr_vec, autodet.thr_vec, pow2db(snr_avg),'previous','extrap');
    ngv_detected = (sig_cor_hd > threshold);
    
    % Continue processing depending on whether packet is legacy or NGV
    if (ngv_detected)
        if (TX.ppdu_fmt ~= 2)
            err = 7;
            return
        end
        % Average over two SIG fields and decode
        COMB_SIG_CFG = sig_rx((x_d0_cfo+x_d1_cfo)/2, snr0+snr1);
        
        if (COMB_SIG_CFG.sig_err ...   % L-SIG error (e.g., from parity bit or bad MCS)
                || COMB_SIG_CFG.mcs ~= 0)    % L-SIG MCS must be 0 in NGV transmissions
            err = 2;
            return
        end
        
        % NGV-SIG samples
        wf_in = rx_wf(idx0:idx0 + 80*n_chan_rx-1,:);
        prev_cfo_corr = r_cfo * sym_since_est;
        new_cfo_weight = 0.5;
        [x_p2, x_d2_cfo, snr2, r_phase_diff2] = sig_pre_rx(wf_in, h_est, sig_data_idx, sig_pilot_idx, n_chan_rx, prev_cfo_corr, new_cfo_weight);
        r_cfo = (r_cfo * sym_since_est + new_cfo_weight *  r_phase_diff2) / sym_since_est;
        idx0 = idx0 + 80*n_chan_rx;
        sym_since_est = 4;
        
        % RNGV-SIG samples
        wf_in = rx_wf(idx0:idx0 + 80*n_chan_rx-1,:);
        prev_cfo_corr = r_cfo * sym_since_est;
        new_cfo_weight = 0.5;
        [x_p3, x_d3_cfo, snr3, r_phase_diff3] = sig_pre_rx(wf_in, h_est, sig_data_idx, sig_pilot_idx, n_chan_rx, prev_cfo_corr, new_cfo_weight);
        r_cfo = (r_cfo * sym_since_est + new_cfo_weight *  r_phase_diff3) / sym_since_est;
        idx0 = idx0 + 80*n_chan_rx;
        sym_since_est = 5;
        
        % Combined NGV-SIG decoding
        NGV_SIG_CFG = ngv_sig_rx((x_d2_cfo+x_d3_cfo)/2, snr2+snr3);
        
        % return if NGV-SIG error detected
        if NGV_SIG_CFG.sig_err
            err = 6;
            return
        end
        
        % Parse parameters into PHY structure
        PHY = ngv_sig_parse(NGV_SIG_CFG, COMB_SIG_CFG.length);
        
        % additional checks for undetected errors
        if (PHY.n_sym ~= size(data_f_mtx, 2) )
            %fprintf('undetected: wrong packet length / n_sym. detected %d should be %d\n',PHY.n_sym, size(data_f_mtx, 2))
            err = 4;
            return
        end
        if (TX.mid ~= PHY.mid)
            err = 4;
            return
        end
        
        % NGV-STF (FIX, does nothing for now)
        idx0 = idx0 + 80*n_chan_rx;
        sym_since_est = 6;
        
        % NGV-LTF updated channel estimation
        n_nltf_samp_tot = PHY.n_ss * PHY.n_ngvltf_samp; % TODO: double check this for 10 MHz packets in 20 MHz RX mode
        cp_len = n_chan_rx*16;
        ofdm_off = cp_len/2;
        wf_in = rx_wf( ((idx0+cp_len):(idx0+n_nltf_samp_tot-1)) - ofdm_off,:);
        % TODO: modify ngv_chan_est to support reception of 10 MHz waveforms when in 20 MHz RX mode
        h_est = ngv_chan_est(wf_in, ofdm_off, PHY.n_ss, n_chan_rx, PHY.n_ngvltf_samp);
        idx0 = idx0 + n_nltf_samp_tot;
    else
        if (TX.ppdu_fmt ~= 1)
            err = 7;
            return
        end
        % Already tried to read RL-SIG, backtrack the RL-SIG samples
        idx0 = idx0 - 80*n_chan_rx;
        
        % Parse L-SIG
        PHY = sig_parse(L_SIG_CFG);
        if L_SIG_CFG.sig_err    % L-SIG error (e.g., from parity bit or bad MCS)
            err = 2;
            return
        end
        if (PHY.psdu_length ~= TX.payload_len)
            %fprintf('11p: undetected sig error: wrong length\n')
            err = 4;
            return
        end
        if (PHY.mcs ~= TX.mcs)
            %fprintf('11p: undetected sig error: wrong mcs\n')
            err = 4;
            return
        end
    end
    
    % Data processing
    [rx_out] = data_rx(PHY, RX, rx_wf, idx0, h_est, data_f_mtx, r_cfo, snr_avg);
    
    if (PHY.ppdu_fmt == 1)
        len = PHY.psdu_length;
    elseif (PHY.ppdu_fmt == 2)
        % For NGV transmissions, the payload length (=MPDU length) must be obtained from the A-MPDU header
        % A-MPDU header starts on the first bit of the PSDU, but rx_out includes also 9 unused bits from service field
        ampdu_eof = rx_out(10);
        ampdu_res = rx_out(11);
        ampdu_len = bi2de(rx_out(12:25)', 'left-msb');
        ampdu_crc_val = crc8(rx_out(10:33)); % TODO: check MSB mode;
        % CRC is performed over whole bit sequence, check result for magic value
        ampdu_crc_ok = (ampdu_crc_val == 12);
        ampdu_sig = bi2de(rx_out(34:41)', 'left-msb');
        if (ampdu_eof == 1 && ampdu_res == 1 && ampdu_sig == 78 && ampdu_crc_ok)
            % valid A-MPDU header
            len = ampdu_len;
            rx_out = rx_out(33:end); % Discard A-MPDU header
            if (ampdu_len + 4 > PHY.psdu_length)
                % A-MPDU header denotes a packet length that cannot fit into PSDU, must be an error
                err = 8;
                return
            end
            if (ampdu_len ~= TX.payload_len)
                % undetected length error
                err = 4;
                return
            end
        else
            % A-MPDU error detected
            err = 8;
            return
        end
    else
        error('ppdu_fmt not supported')
    end
    
    % Check if payload length is correct and perform CRC
    if (len >= 5)
        % Convert to bytes
        pld_bytes = bi2de(reshape(rx_out(10:10 + len*8 - 1), 8, len)');
        
        % Calculate CRC-32
        pld_crc32 = crc32(pld_bytes(1:len - 4)');
        
        % Check CRC for errors
        if (any(pld_crc32(len - 3:len) ~= pld_bytes(len - 3:len)'))
            err = 3;
        end
    else
        err = 2;
    end
end

end
