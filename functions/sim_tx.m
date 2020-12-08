function [tx_wf, data_f_mtx, data_msg, PHY] = sim_tx(TX)
%SIM_TX High-level transmitter function
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

% Create structure with PHY parameters
[PHY, data_msg] = tx_phy_params('TX', TX.mcs, TX.payload_len, TX.ppdu_fmt, TX.mid, TX.n_ss, TX.ltf_fmt_init, TX.n_chan, 0, 0);

% Get L-STF waveform
stf_wf = stf_tx(TX.w_beta, PHY.n_chan);

% Get L-LTF waveform
ltf_wf = ltf_tx(TX.w_beta, PHY.n_chan);

% Get L-SIG waveform
sig_wf = sig_tx(PHY, TX, PHY.n_chan);

% NGV preamble symbols
if (TX.ppdu_fmt == 1)
    % Calculate number of required pad bits
    pad_len = PHY.n_sym*PHY.n_dbps - (16 + 8*PHY.psdu_length + 6);
    
    % Add service and zero-padding (pad + tail)
    padding_out = [false(16, 1); data_msg; false(pad_len + 6, 1)];
    
    ngv_sig_wf = [];
    ngv_stf_wf = [];
    ngv_ltf_wf = [];
    
elseif (TX.ppdu_fmt == 2)
    if (TX.mcs == 0 || TX.mcs == 10)
        % BPSK or BPSK-DCM. Apply power scaling for L-STF and L-LTF
        stf_wf = sqrt(2)*stf_wf;
        ltf_wf = sqrt(2)*ltf_wf;
    end
    % NGV-SIG
    ngv_sig_wf = ngv_sig_tx(PHY, TX.w_beta, PHY.n_chan);
    
    % NGV-STF
    ngv_stf_wf = ngv_stf_tx(TX.w_beta, PHY.n_chan);
    
    % NGV-LTF
    ngv_ltf_wf = ngv_ltf_tx(TX.w_beta, PHY.n_chan, TX.n_ss, PHY.ngvltf_fmt);
    
    % MAC and PHY padding for LDPC
    Npld = PHY.LDPC.Npld;
    pad_len = Npld - (TX.payload_len+4)*8 - 16; % Total length of MAC + PHY padding (bits)
     
    % Add service and zero-padding
    padding_out = [false(16, 1); data_msg;  false(pad_len, 1)];
else
    error('PPDU format not supported')
end

% Generate data waveform
[data_wf, data_f_mtx] = data_tx(PHY, pad_len, padding_out, TX.w_beta);

% Concatenate output waveform
if (TX.ppdu_fmt == 1)
    cyc_shift_leg = [0 2]*PHY.n_chan; % 200 nanoseconds
    tx_wf1 = [stf_wf; ltf_wf; sig_wf; data_wf];
    tx_wf = complex(zeros(size(tx_wf1,1), TX.n_tx_ant));
    for i_tx = 1:TX.n_tx_ant
        cyc_l = cyc_shift_leg(i_tx);
        %tx_wf(:,i_tx) = [stf_wf; ltf_wf; sig_wf; sig_wf; ngv_sig_wf; ngv_sig_wf; ngv_stf_wf; ngv_ltf_wf; data_wf];
        tx_wf(:,i_tx) = [circshift(stf_wf, cyc_l); circshift(ltf_wf, cyc_l); circshift(sig_wf, cyc_l); circshift(data_wf, cyc_l)];
    end
else
    cyc_shift_leg = [0 2]*PHY.n_chan; % 200 nanoseconds
    cyc_shift_ngv = [0 4]*PHY.n_chan; % is still TBD
    tx_wf1 = [stf_wf; ltf_wf; sig_wf; sig_wf; ngv_sig_wf; ngv_sig_wf; ngv_stf_wf; ngv_ltf_wf; data_wf];
    tx_wf = complex(zeros(size(tx_wf1,1), TX.n_tx_ant));
    for i_tx = 1:TX.n_tx_ant
        cyc_l = cyc_shift_leg(i_tx);
        cyc_n = cyc_shift_ngv(i_tx);
        tx_wf(:,i_tx) = [circshift(stf_wf(:,1), cyc_l); circshift(ltf_wf(:,1), cyc_l); circshift(sig_wf(:,1), cyc_l); circshift(sig_wf(:,1), cyc_l); circshift(ngv_sig_wf(:,1), cyc_l); circshift(ngv_sig_wf(:,1), cyc_l); circshift(ngv_stf_wf(:,1), cyc_n); circshift(ngv_ltf_wf(:,1), cyc_n); circshift(data_wf(:,1), cyc_n)];
    end
end

% Apply time-domain windowing
if (TX.window_en)
    if (PHY.ngvltf_fmt ~= 0 || TX.bw_mhz ~= 10)
        error('TX time-domain windowing is not supported in this mode')
    end
    tx_wf = apply_time_window(tx_wf, TX.window_en);
end

end
