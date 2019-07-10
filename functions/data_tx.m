function [data_wf, data_f_mtx] = data_tx(PHY, LDPC, pad_len, padding_out, w_beta)
%DATA_TX Transmitter processing of all DATA OFDM symbols
%
%   Author: Ioannis Sarris, u-blox
%   email: ioannis.sarris@u-blox.com
%   August 2018; Last revision: 10-July-2019

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
padding_vec = [true(16 + PHY.length*8, 1); false(6, 1); true(pad_len, 1)];

% Find number of midamble symbols
i_mid = 0;
if (PHY.mid_period == 0)
    n_mid = 0;
else
    n_mid = floor(PHY.n_sym/PHY.mid_period);
end

% Initialize time-domain waveform output
data_wf = complex(zeros((PHY.n_sym + n_mid)*80, 1));

% Initialize frequency-domain output
data_f_mtx = complex(zeros(64, PHY.n_sym));

% Perform LDPC encoding
ldpc_out = false;
if PHY.ldpc_en
    [~, scrambler_out] = scrambler_tx(padding_out, PHY.pn_seq);
    ldpc_out = ldpc_enc(LDPC, scrambler_out);
end

% Loop for each OFDM symbol
for i_sym = 0:PHY.n_sym - 1
    
    % Process through FEC
    if PHY.ldpc_en
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
        end
    end
    
    % Apply interleaving per OFDM symbol
    interlvr_out = interleaver(fec_out, PHY.n_bpscs, PHY.n_cbps, PHY.ppdu_fmt);
    
    % Initialize f-domain data symbol
    data_f = complex(zeros(64, 1));
    
    % Insert pilots with correct polarity
    data_f(PHY.pilot_idx, 1) = PHY.polarity_sign(mod(i_sym + PHY.pilot_offset, 127) + 1)*PHY.pilot_val(1:4, :);
    
    % Modulate binary data
    mod_data = mapper_tx(interlvr_out, PHY.n_bpscs);
    
    % Insert modulated data into f-domain data symbol
    if (PHY.ldpc_en)
        data_f(PHY.data_idx, 1) = ldpc_tonemap(mod_data, 64);
    else
        data_f(PHY.data_idx, 1) = mod_data;
    end
    
    % Apply spectral shaping window
    data_fs = data_f.*kaiser(64, w_beta);
    
    % Perform IFFT & normalize
    temp_wf = 1/sqrt(PHY.n_sd + 4)*dot11_ifft(data_fs, 64);
    
    % Keep track of midamble symbols used
    if (PHY.mid_period > 0)
        i_mid = floor((i_sym + 1)/PHY.mid_period);
    end
    
    % Append CP
    data_wf((1:80) + (i_sym + i_mid)*80 , :) = [temp_wf(49:64); temp_wf];
    
    % If this is a midamble symbol insert LTF sequence
    if (mod((i_sym + 1), PHY.mid_period) == 0)
        tmp = ngv_ltf_tx(w_beta);
        data_wf((1:80) + (i_sym + i_mid - 1)*80 , :) = tmp;
    end
    
    % Store f-domain symbols which are needed for (genie) channel tracking at the Rx
    data_f_mtx(:, i_sym + 1) = data_f;
end

end
