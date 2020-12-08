function check_sp_mask(in, filt_len, n_sym, ovs, enabled)
%CHECK_SP_MASK Check spectral mask of transmitted waveform for compliance to Class C specifications
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

if enabled
    % Start/end indices of DATA
    idx0 = filt_len/2 + (160 + 160 + 80)*ovs;
    idx1 = idx0 + n_sym*80*ovs;
    
    % Select DATA waveform
    in = in(idx0:idx1);
    
    % IEEE Std 802.11-2012 Annex D.2.3, Table D-5: Class C STA
    dBrLimits = [-50  -50 -40 -32  -26 0   0  -26 -32 -40 -50 -50];
    fLimits   = [-Inf -15 -10 -5.5 -5 -4.5 4.5 5  5.5  10  15 Inf];
    
    vbw = 300;          % Video bandwidth
    rbw = 100e3;        % Resolution bandwidth
    N = floor(rbw/vbw); % Number of spectral averages
    
    % Construct dsp.SpectrumAnalyzer and set SpectralMask property
    spectrumAnalyzer = dsp.SpectrumAnalyzer(...
        'SampleRate', 10e6*ovs, ...
        'SpectrumType','Power density', ...
        'PowerUnits','dBm', ...
        'SpectralAverages',N, ...
        'RBWSource','Property', ...
        'RBW',rbw, ...
        'ReducePlotRate',false, ...
        'ShowLegend',true, ...
        'Name', 'Spectrum Analyzer');
    spectrumAnalyzer.SpectralMask.EnabledMasks = 'Upper';
    spectrumAnalyzer.SpectralMask.ReferenceLevel = 'Spectrum peak';
    spectrumAnalyzer.SpectralMask.UpperMask = [fLimits*1e6; dBrLimits].';
    
    % Get the number of segments to process
    setup(spectrumAnalyzer, complex(in(1)));
    segLen = spectrumAnalyzer.getFramework.Visual.SpectrumObject.getInputSamplesPerUpdate(true);
    numSegments = floor(size(in, 1)/segLen);
    
    % Process each segment and test the PSD against the mask
    for idx = 1:numSegments
        spectrumAnalyzer(in((idx - 1)*segLen + (1:segLen), 1));
    end
    release(spectrumAnalyzer);
    assignin('caller', 'spectrumAnalyzer', spectrumAnalyzer);
end
