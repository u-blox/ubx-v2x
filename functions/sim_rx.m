function [pld_bytes, err] = sim_rx(rx_wf, s0_len, pdet_thold)
%SIM_RX High-level receiver function
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

% Needed for code generation
coder.varsize('rx_out', [8*4096 1], [1 0]);

% Initialize PHY parameters
PHY = rx_phy_params;

% Packet detection / coarse CFO estimation
[c_idx, c_cfo, pdet_err] = pdet(rx_wf, s0_len, pdet_thold);

% If no packet error, proceed with packet decoding
err = 0;
pld_bytes = [];
if pdet_err
    err = 1;
else
    % Coarse CFO correction
    rx_wf = apply_cfo(rx_wf, -c_cfo/5.9e9*10e6);
    
    % Fine synchronization / fine CFO estimation
    [f_idx, f_cfo] = fine_sync(rx_wf, c_idx);
    
    % Fine CFO correction
    rx_wf = apply_cfo(rx_wf, -f_cfo/5.9e9*10e6);
    
    % Channel estimation
    wf_in = rx_wf(f_idx:f_idx + 127);
    h_est = chan_est(wf_in);
    
    % SIG reception
    idx = f_idx + 128 + 16;
    wf_in = rx_wf(idx:idx + 63);
    [SIG_CFG, r_cfo] = sig_rx(wf_in, h_est, PHY.data_idx, PHY.pilot_idx);
    
    % Detect SIG errors and abort or proceed with data processing
    if (SIG_CFG.sig_err)
        err = 2;
    else
        
        % Update PHY parameters based on SIG
        PHY = update_phy_params(PHY, SIG_CFG.mcs, SIG_CFG.length);
        
        % Data processing
        rx_out = data_rx(PHY, SIG_CFG, rx_wf, idx, h_est, r_cfo);
        
        % Check if payload length is correct
        len = SIG_CFG.length;
        if (len >= 5)
            
            % Convert to bytes
            pld_bytes = bi2de(reshape(rx_out(10:10 + len*8 - 1), 8, len)');
            
            % Calculate CRC-32
            pld_crc32 = double(crc32(pld_bytes(1:len - 4, 1)'));
            
            % Check CRC for errors
            if (any(pld_crc32(1, len - 3:len) ~= pld_bytes(len - 3:len, 1)'))
                err = 3;
            end
        else
            err = 2;
        end
    end
end

end
