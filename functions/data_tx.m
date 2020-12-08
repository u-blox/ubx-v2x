function [data_wf, data_f_mtx] = data_tx(PHY, pad_len, padding_out, w_beta)
%DATA_TX Transmitter processing of all DATA OFDM symbols
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

% Store this as a persistent variable to avoid reinitialization
persistent bcc_obj

% Needed for code generation
coder.varsize('scrambler_out', [4097*8 1], [1 0]);

% Initialize parameters
n_fft = PHY.n_chan*64;
cp_len = PHY.n_chan*16;
n_sps = n_fft + cp_len;

% Create or reset system object
if isempty(bcc_obj)
    bcc_obj = comm.ConvolutionalEncoder( ...
        'TrellisStructure', poly2trellis(7, [133 171]), ...
        'PuncturePatternSource', 'Property', ...
        'PuncturePattern', [1; 1]);
else
    reset(bcc_obj);
end

% Initialize state of PN generator
pn_state = flipud(PHY.pn_seq);

% Mark the tail bits so that they can be nulled after scrambling
padding_vec = [true(16 + PHY.psdu_length*8, 1); false(6, 1); true(pad_len, 1)];

% Find number of midamble symbols
n_nltf_samples_tot = PHY.n_ss * PHY.n_ngvltf_samp;

% Initialize time-domain waveform output
data_wf = complex(zeros(PHY.n_sym*n_sps + PHY.n_mid*n_nltf_samples_tot, 1));

% Initialize frequency-domain output
data_f_mtx = complex(zeros(n_fft, PHY.n_sym));

% Perform LDPC encoding
ldpc_out = false;
if (PHY.ppdu_fmt == 2)
    [~, scrambler_out] = scrambler_tx(padding_out, PHY.pn_seq);
    ldpc_out = ldpc_enc(PHY.LDPC, scrambler_out);
end

% Loop for each OFDM symbol
i_mid = 0;
for i_sym = 0:PHY.n_sym - 1
    
    % Process through FEC
    if (PHY.ppdu_fmt == 2)
        fec_out = ldpc_out(i_sym*PHY.n_cbps + 1:(i_sym + 1)*PHY.n_cbps);
    else
        % Index of bits into scrambler per OFDM symbol
        idx0 = i_sym*PHY.n_dbps + 1;
        idx1 = (i_sym + 1)*PHY.n_dbps;
        
        % Perform scrambling with given PN sequence
        [pn_state, scrambler_out] = scrambler_tx(padding_out(idx0:idx1), pn_state);
        
        % Set scrambled tail bits to zero
        scrambler_out = (scrambler_out & padding_vec(idx0:idx1));
        
        % Process data through BCC encoder
        fec_out = step(bcc_obj, scrambler_out);
        
        % Perform puncturing if needed
        switch PHY.r_num
            case 2
                a1 = reshape(fec_out, 4, []);
                a2 = a1([1 2 3], :);
                fec_out = a2(:);
            case 3
                a1 = reshape(fec_out, 6, []);
                a2 = a1([1 2 3 6], :);
                fec_out = a2(:);
            case 5
                a1 = reshape(fec_out, 10, []);
                a2 = a1([1 2 3 6 7 10], :);
                fec_out = a2(:);
        end
    end
    
    % Apply interleaving per OFDM symbol
    interlvr_out = interleaver(fec_out, PHY.n_bpscs, PHY.n_cbps, PHY.ppdu_fmt, PHY.n_chan);
    
    % Initialize f-domain data symbol
    data_f = complex(zeros(n_fft, 1));
    
    % Insert pilots with correct polarity
    if PHY.ppdu_fmt == 1
        pilot_val = PHY.pilot_val;
    else
        pilot_val = circshift(PHY.pilot_val, - i_sym);
    end
    data_f(PHY.pilot_idx, 1) = PHY.polarity_sign(mod(i_sym + PHY.pilot_offset, 127) + 1)*pilot_val;
    
    % Modulate binary data
    mod_data = mapper_tx(interlvr_out, PHY.n_bpscs);
    
    % Insert modulated data into f-domain data symbol
    data_f(PHY.data_idx, 1) = mod_data;
    
    % Apply spectral shaping window
    data_fs = data_f.*kaiser(n_fft, w_beta);
    
    % Perform IFFT & normalize
    temp_wf = 1/sqrt(PHY.n_sd + length(PHY.pilot_idx))*dot11_ifft(data_fs, n_fft);
    
    % Append CP and insert into transmit waveform
    offset = i_sym*n_sps + i_mid*n_nltf_samples_tot;
    data_wf((1:n_sps) + offset, :) = [temp_wf(n_fft-cp_len+1:n_fft); temp_wf];
    
    % If this data symbol is followed by a midamble symbol, insert NGV-LTF sequence
    % The last data symbol is never followed by a midamble!
    if (mod((i_sym + 1), PHY.mid) == 0 && i_sym < PHY.n_sym - 1)
        ltf_wf = ngv_ltf_tx(w_beta, PHY.n_chan, PHY.n_ss, PHY.ngvltf_fmt);
        offset = (i_sym+1)*n_sps + i_mid*n_nltf_samples_tot;
        data_wf((1:n_nltf_samples_tot) + offset, :) = ltf_wf;
        % Keep track of midamble symbols used
        i_mid = i_mid + 1;
    end
    
    % Store f-domain symbols which are needed for (genie) channel tracking at the Rx
    data_f_mtx(:, i_sym + 1) = data_f;
end

end
