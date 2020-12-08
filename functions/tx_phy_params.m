function [PHY, data_msg] = tx_phy_params(mode, mcs, tx_payload_len, ppdu_fmt, mid, n_ss, ngvltf_fmt, n_chan, rx_lsig_len, rx_ngvsig_extra_sym)
%TX_PHY_PARAMS Initializes PHY layer parameters
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

% Store MCS / payload length
PHY.mcs         = mcs;
PHY.ppdu_fmt    = ppdu_fmt;
PHY.n_chan      = n_chan;
PHY.n_ss        = n_ss;

% Initialize scrambler with a 7-bit non-allzero PN sequence (random or pre-set)
PHY.pn_seq = logical(de2bi(randi([1 127]), 7, 'left-msb'))';

% SIG pilot subcarrier indices and values
PHY.sig_pilot_idx = [-21 -7 7 21].' + 33;
PHY.sig_pilot_val = [1 1 1 -1].';

% Polarity signs to use for pilots
PHY.polarity_sign = [1,1,1,1,-1,-1,-1,1,-1,-1,-1,-1,1,1,-1,1,-1,-1,1,1,-1,1,1,-1,1,1,1,1,1,1,-1,1,1,1,-1,1,1,-1,-1,1,1,1, ...
    -1,1,-1,-1,-1,1,-1,1,-1,-1,1,-1,-1,1,1,1,1,1,-1,-1,1,1,-1,-1,1,-1,1,-1,1,1,-1,-1,-1,1,1,-1,-1,-1,-1,1,-1,-1,1, ...
    -1,1,1,1,1,-1,1,-1,1,-1,1,-1,-1,-1,-1,-1,1,-1,1,1,-1,1,-1,1,1,1,-1,-1,1,-1,-1,-1,1,1,1,-1,-1,-1,-1,-1,-1,-1].';

% SIG data subcarrier indices
PHY.sig_data_idx = [-26:-22 -20:-8 -6:-1 1:6 8:20 22:26].' + 33;

% Legacy (1) or NGV (2) PPDU format
if (ppdu_fmt == 1)
    % MCS tables for coding rate (numerator / denominator) and bits per modulation symbol
    r_num_vec =   [1 3 1 3 1 3 2 3];
    r_denom_vec = [2 4 2 4 2 4 3 4];
    n_bpscs_vec = [1 1 2 2 4 4 6 6];
    
    % Number of data subcarriers and tones
    n_sd = 48;
    n_st = 52;
    
    % Pilot subcarrier indices and values
    PHY.pilot_idx = [-21 -7 7 21].' + 33;
    PHY.pilot_val = [1 1 1 -1].';
    
    % Data subcarrier indices
    PHY.data_idx  = [-26:-22 -20:-8 -6:-1 1:6 8:20 22:26].' + 33;
    PHY.pilot_offset = 1;
    
    PHY.ngvltf_fmt     = 0;
    PHY.t_ngvltf       = 0;
    PHY.n_ngvltf_samp  = 0;
elseif (ppdu_fmt == 2)
    % MCS tables for coding rate (numerator / denominator) and bits per modulation symbol
    % NGV-MCS. Source: Specification Framework Document 11-19-0497-06
    r_num_vec =   [1 1 3 1 3 2 3 5 3 5 1];
    r_denom_vec = [2 2 4 2 4 3 4 6 4 6 2];
    n_bpscs_vec = [1 2 2 4 4 6 6 6 8 8 0.5]; % 0.5 is for BSPK with DCM
    
    if (n_chan == 1)
        % Number of data subcarriers and tones
        n_sd = 52;
        n_st = 56;
        
        % Pilot subcarrier indices and values
        PHY.pilot_idx = [-22 -8 8 22].' + 33; % different from SIG pilot indices
        PHY.pilot_val = [1 1 1 -1].';
        
        % Data subcarrier indices
        PHY.data_idx = [-28:-23 -21:-9 -7:-1 1:7 9:21 23:28].' + 33;
    elseif (n_chan == 2)
        % Number of data subcarriers and tones
        n_sd = 108;
        n_st = 114;
        
        % Pilot subcarrier indices and values
        PHY.pilot_idx = [-54 -26 -12 12 26 54].' + 65;
        PHY.pilot_val = [1 1 1 -1 -1 1].'; % first row in table 19-20
        
        % Data subcarrier indices
        PHY.data_idx = [-58:-55 -53:-27 -25:-13 -11:-2 2:11 13:25 27:53 55:58].' + 65;
    else
        error('bw not supported');
    end
    
    PHY.pilot_offset = 4;
    
    % NGV-LTF parameters
    if (mcs == 10)
        % MCS 10 must always use ngvltf_fmt 2 (NGV-LTF-repeat)
        ngvltf_fmt = 2;
    end
    t_ngvltf_vec = [8, 4.8, 14.4];
    t_ngvltf = t_ngvltf_vec(ngvltf_fmt+1);
    PHY.ngvltf_fmt     = ngvltf_fmt;
    PHY.t_ngvltf       = t_ngvltf;
    PHY.n_ngvltf_samp  = t_ngvltf * 10* n_chan;
else
    % Prevent errors in code generation
    error('ppdu_fmt not supported')
end

% Find code rate numerator/denominator & bits per modulation symbol
PHY.r_num   = r_num_vec(mcs + 1);
PHY.r_denom = r_denom_vec(mcs + 1);
PHY.n_bpscs = n_bpscs_vec(mcs + 1);

% Calculate coded/uncoded number of bits per OFDM symbol
n_cbps  = n_sd*n_bpscs_vec(mcs + 1);
n_dbps  = n_sd*n_bpscs_vec(mcs + 1)*r_num_vec(mcs + 1)/r_denom_vec(mcs + 1);

% Extra step to enable code generation
PHY.n_sd    = n_sd;
PHY.n_st    = n_st;
PHY.n_cbps  = n_cbps;
PHY.n_dbps  = n_dbps;

% Calculate number of OFDM symbols, different value for 802.11p/802.11bd
if (ppdu_fmt == 1)
    if strcmp(mode, 'RX')
        % receiver side: LSIG length value is given
        psdu_length = rx_lsig_len;
    else
        % transmitter side, .11p: psdu_length is always equal to payload_len (no padding)
        psdu_length = tx_payload_len;
    end
    
    LDPC = ldpc_enc_params(401, 26, 52); % necessary for codegen, with example values that don't cause errors
    PHY.n_sym = ceil((16 + 8*psdu_length + 6)/n_dbps);
    PHY.mid   = 0; % midambles are disabled
    PHY.n_mid = 0; % no midamble symbols
elseif (ppdu_fmt == 2)
    Nservice = 16;
    if strcmp(mode, 'RX')
        % receiver side: compute psdu length from RX_TIME and other parameters
        n_ngvltf = n_ss;
        time_sym = 8;
        time_training = n_ngvltf * t_ngvltf;
        time_mid = time_training;
        % NGV part of the preamble: RL-SIG + NGV-SIG + RNGV-SIG + NGV-STF + multiple NGV-LTFs
        time_ngv_pre = 8 + 8 + 8 + 8 + time_training;
        
        % Obtain RX time from length field in SIG. Always integer because sig_length must be modulo 3
        rx_time_after_leg = (rx_lsig_len + 3)/3*8;
        rx_time_data_field = rx_time_after_leg - time_ngv_pre;
        
        % Duration of M data symbols followed by one midamble
        time_mid_rep = time_mid + mid*time_sym;
        
        % Number of Midambles
        n_mid_rx = floor((rx_time_data_field-time_sym)/time_mid_rep); % (32-44) in D0.3
        
        % Total number of received data symbols (symbols in the data field that are not midambles)
        n_sym_rx_prime = floor((rx_time_data_field - n_mid_rx*time_mid)/8); % (32-43) in D0.3
        
        % Get the basic number of symbols (subtract 0 or 1 LDPC extra symbol)
        n_sym_rx_basic = n_sym_rx_prime - rx_ngvsig_extra_sym;
        
        % Compute the total number of data bits on the PHY (includes 0-7 bits of PHY padding)
        phy_length_bits_padded = n_sym_rx_basic*n_dbps - Nservice;
        
        % Compute PSDU length
        psdu_length = floor(phy_length_bits_padded/8);
        
        % LDPC decoding parameters
        LDPC = ldpc_enc_params(psdu_length, n_dbps, n_cbps);
        PHY.n_sym = LDPC.Nsym;
        PHY.mid = mid;
        PHY.n_mid = n_mid_rx;
    elseif strcmp(mode, 'TX')
        % Get the minimum PSDU length required to fit an MPDU of length tx_payload_len (add 4 Byte A-MPDU header)
        min_psdu_length = tx_payload_len + 4;
        
        % Get the basic number of data symbols required to transmit the payload
        n_sym_basic = ceil((min_psdu_length*8 + Nservice)/n_dbps);
        
        % Compute PSDU length. Length of the phy payload (MAC payload_length + MAC padding bytes). Does NOT include the 0-7 PHY padding bits.
        psdu_length = floor((n_sym_basic*n_dbps - Nservice)/8);
               
        % LDPC encoding parameters
        LDPC = ldpc_enc_params(psdu_length, n_dbps, n_cbps);
        
        % Total number of transmitted data symbols, equal to n_sym_basic + (0 or 1 LDPC extra symbol)
        PHY.n_sym = LDPC.Nsym;
        PHY.mid = mid;
        PHY.n_mid = floor((LDPC.Nsym-1)/(mid)); %TODO double-check this!
    else
        error('mode must be RX or TX')
    end
else
    error('ppdu_fmt not supported')
end

PHY.psdu_length = psdu_length;
PHY.LDPC = LDPC;

% Create pseudo-random PSDU binary message (account for CRC-32)
tmp_msg = randi([0 255], tx_payload_len - 4, 1)';

% Calculate CRC-32
data_msg_crc = crc32(tmp_msg);

% Convert byte to binary data
data_msg = logical(de2bi(data_msg_crc, 8))';
data_msg = data_msg(:);

if (ppdu_fmt == 2)
    % Prepend A-MPDU header
    eof   = 1;
    res   = 1;
    len   = de2bi(tx_payload_len, 14, 'left-msb')'; % TODO: check MSB mode
    crc   = de2bi(crc8([eof; res; len]), 8, 'left-msb')'; % TODO: check MSB mode
    % ASCII 'N' signature field
    signature   = de2bi(64+14,8,  'left-msb')'; % TODO: check MSB mode
    ampdu_header = [eof; res; len; crc; signature];
    data_msg = [logical(ampdu_header); data_msg];
end

end
