function ldpcPara = ldpc_enc_params(psdu_length, Ndbps, Ncbps)
%LDPC_ENC_PARAMS Returns LDPC encoding parameters
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

rate  = Ndbps/Ncbps;
Nservice = 16;

% a) Compute the number of available bits
% The initial number of OFDM symbols required.
n_sym_basic = ceil((psdu_length*8 + Nservice)/Ndbps);

% The number of payload bits. Stays the same, regardless of LDPC extra symbol.
Npld = n_sym_basic*Ndbps;

% The initial number of coded bits. Stays the same, regardless of LDPC extra symbol.
Navbits_init = Ncbps*ceil(Npld/(Ndbps));

% The total number of coded bits. This is increased if an LDPC extra symbol is required
Navbits = Navbits_init;

% % Sanity checks:
% psduLength2 = floor((n_sym_basic*Ndbps-Nservice)/8); % PSDU_length. Length of the phy payload (a_mpdu_payload_length + MAC padding bytes, but NOT the 0-7 PHY padding bits)
% additional_pad = psduLength2 - psdu_length;
% if additional_pad ~= 0
%     error('Wrong PSDU Length (MAC padding is required)')
% end
% Nphypad = Npld - psduLength2*8 - Nservice;
% if Nphypad > 7
%     error('Wrong PSDU Length (MAC padding is required)')
% end

% b) Compute the integer number of LDPC codewords to be transmitted
[Lldpc, Ncw, FileIdx] = getEncPara( Navbits, Npld, rate);
K0 = Lldpc * rate;

% c) Compute number of shortening bits
tem = Ncw * Lldpc * rate - Npld;
Nshrt = max(0, tem);
vNshrt = zeros(1, Ncw);

if( Nshrt > 0)
    Nspcw = floor( Nshrt / Ncw);
    Nsp1 = rem( Nshrt, Ncw);
    vNshrt(1: Nsp1) = Nspcw + 1;  % indicate codewords where bit index (k-Nspcw-1 : k-1) will be set to zero
    vNshrt(Nsp1+1 : Ncw) = Nspcw; % indicate codewords where bit index (k-Nspcw : k-1) will be set to zero
end

vCwLen = Lldpc - vNshrt;

% d) Compute bit to be punctured
tem = (Ncw * Lldpc) - Navbits - Nshrt;
Npunc = max( 0, tem);

temA = 0.1 * Ncw * Lldpc * (1-rate);
temB = 1.2 * Npunc * (rate /(1-rate));
temC = 0.3 * Ncw * Lldpc *(1-rate);

extra = 0;
if( ( (Npunc > temA) && (Nshrt < temB)) || (Npunc > temC))
    % examples:
    % MCS-0, payload 350: no extra symbol
    % MSC-1, payload 400: extra symbol
    extra = 1;
    Navbits = Navbits + Ncbps;
    tem = (Ncw * Lldpc) - Navbits - Nshrt;
    Npunc = max( 0, tem);
end

Nppcw = floor( Npunc/ Ncw);   vNpunc = zeros(1, Ncw);
Nsym = Navbits / Ncbps; % Nsym includes the extra symbol.

if (Npunc > 0)
    Npp1 = rem( Npunc, Ncw);  % discard parity bits: (n-k-Nppcw-1 : n-k-1)
    vNpunc(1: Npp1) = Nppcw + 1;
    vNpunc(Npp1+1 : Ncw) = Nppcw; % discard parity bits: (n-k-Nppcw : n-k-1)
    
    vCwLen = vCwLen - vNpunc;
end

% e) Compute number of coded bits to be repeated, valid only when Npunc==0
tem = Navbits - (Ncw * Lldpc * (1-rate)) - Npld;
Nrep = max(0, round(tem));
vNrepInt = zeros(1, Ncw);  vNrepRem = zeros(1, Ncw);

if( Npunc == 0 && Nrep > 0)
    repBit = floor( Nrep / Ncw);  % repeat bits for each codeword
    Np1 = rem( Nrep, Ncw);  % one more bits should be repeated
    
    vRep = ones(1, Ncw) * repBit;
    vRep(1:Np1) = repBit + 1;  % 1-by-Ncw, repeat bits for each codeword
    
    vNrepInt = floor( vRep ./ vCwLen);
    vNrepRem = vRep - vNrepInt .* vCwLen;
    
    vCwLen = vCwLen + vRep;
end

ldpcPara.Lldpc   = Lldpc;
ldpcPara.Ncw     = Ncw;
ldpcPara.Nsym    = Nsym;
ldpcPara.Ndbps   = Ndbps;
ldpcPara.Ncbps   = Ncbps;
ldpcPara.Npld    = Npld;
ldpcPara.Navbits = Navbits;
ldpcPara.K0      = K0;
ldpcPara.rate    = rate;
ldpcPara.extra   = extra;

ldpcPara.Nshrt   = Nshrt;
ldpcPara.Npunc   = Npunc;
ldpcPara.Nrep    = Nrep;

% the following vectors are 1-by-Ncw
ldpcPara.vNshrt   = vNshrt;  % Nspcw for each codeword:
ldpcPara.vNpunc   = vNpunc;     % Nppcw for each codeword
ldpcPara.vNrepInt = vNrepInt; % repeat number of the whole codeword
ldpcPara.vNrepRem = vNrepRem; % repeat number of bits in a codeword

ldpcPara.vCwLen   = vCwLen;   % codeword length after discard shorten bits, punc or repeat

ldpcPara.FileIdx  = FileIdx;
return;


function [Lldpc, Ncw, FileIdx] = getEncPara( Navbits, Npld, rate)
% Table20-15: PPDU encoding parameters
% Lldpc: LDPC codeworklength
% Ncw: number of LDPC codewords
% FileIdx: index of generating matrix
%    FileIdx.idxCwLen: index of codeword length: [648, 1296, 1944] => [1, 2, 3]
%    FileIdx.idxRate: index of rate: [1/2, 2/3, 3/4, 5/6] => [1, 2, 3, 4]
% Npld: number of bits int ehPSDU and SERVICE field

if( Navbits <= 648)
    Ncw = 1;
    tem = Npld + 912*(1-rate);
    if( Navbits >= tem)
        Lldpc = 1296;
    else
        Lldpc = 648;
    end
    
elseif( Navbits <= 1296)
    Ncw = 1;
    tem = Npld + 1464*(1-rate);
    if( Navbits >= tem)
        Lldpc = 1944;
    else
        Lldpc = 1296;
    end
    
elseif( Navbits <= 1944)
    Ncw = 1;
    Lldpc = 1944;
    
elseif( Navbits <= 2592)
    Ncw = 2;
    tem = Npld + 2916*(1-rate);
    if( Navbits >= tem)
        Lldpc = 1944;
    else
        Lldpc = 1296;
    end
    
else  % Navbits > 2592
    Ncw = ceil( Npld / (1944 * rate));
    Lldpc = 1944;
end

switch( Lldpc)
    case 648,   FileIdx.idxCwLen = 1;
    case 1296,  FileIdx.idxCwLen = 2;
    case 1944,  FileIdx.idxCwLen = 3;
    otherwise,  FileIdx.idxCwLen = 0; error('unknown codeword length');
end

% rate: 1/2, 2/3, 3/4, 5/6
rateScale = rate * 12;
switch( rateScale)
    case 6,     FileIdx.idxRate = 1;
    case 8,     FileIdx.idxRate = 2;
    case 9,     FileIdx.idxRate = 3;
    case 10,    FileIdx.idxRate = 4;
    otherwise,  FileIdx.idxCwLen = 0; error('unknown codeword length');
end

return;
