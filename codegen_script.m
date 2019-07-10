%CODEGEN_SCRIPT - Generates MEX files for acceleration purposes
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

addpath('./functions')
clc

tic
disp('Creating MEX for sim_tx')
codegen -args {TX} sim_tx -o ./mex/sim_tx_mex -config:mex -report
toc

tic
disp('Creating MEX for sim_rx')
codegen -args {coder.typeof(1j, [inf 1], [1 0]), 0, coder.typeof(1j, [64 1400], [0 1]), 0, 0, 0, 0, true} sim_rx -o ./mex/sim_rx_mex -config:mex -report
toc
