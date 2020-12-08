%CODEGEN_SCRIPT - Generates MEX files for acceleration purposes
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

addpath('./functions')
clc

if isempty('TX')
    error('First run batch_sim.m to create parameter structures')
end

tic
disp('Creating MEX for sim_tx')
codegen -args {TX} sim_tx -o ./mex/sim_tx_mex -config:mex -report
toc

tic
disp('Creating MEX for sim_rx')
codegen -args {coder.typeof(1j,[inf 4], [1 1]), coder.typeof(1j, [128 1400], [1 1]), RX, TX, 0} ... 
            sim_rx -o ./mex/sim_rx_mex -config:mex -report
toc

