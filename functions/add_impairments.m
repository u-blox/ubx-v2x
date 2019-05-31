function [rx_wf, s0_len] = add_impairments(SIM, tx_wf)

% Add CFO error, assume [-5, 5] ppm per Tx/Rx device
if SIM.apply_cfo
    cfo_err = sum(rand(2, 1)*10 - 5)*1e-6;
    tx_wf = apply_cfo(tx_wf, cfo_err);
end

% Append silence samples at the beginning/end of useful waveform
s0_len = randi([100 200]);
tx_wf_full = [zeros(s0_len, 1); tx_wf; zeros((300 - s0_len), 1)];

% Add AWGN noise
rx_wf = awgn(tx_wf_full, SIM.snr);