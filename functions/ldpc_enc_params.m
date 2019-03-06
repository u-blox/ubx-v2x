function ldpcPara = ldpc_enc_params(payload_length, Ndbps, Ncbps)
%LDPC_ENC_PARAMS Returns LDPC encoding parameters
%
%   Author: Ioannis Sarris, u-blox
%   email: ioannis.sarris@u-blox.com
%   March 2019; Last revision: 06-March-2019

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

% a) Compute the number of available bits
Npld = payload_length*8 + 16;
Navbits = Ncbps*ceil(Npld/(Ndbps));

% b) Compute the integer number of LDPC codewords to be transmitted
[Lldpc, Ncw, FileIdx] = getEncPara( Navbits, Npld, rate);
K0 = Lldpc * rate;

% c) Compute nubmer of shortening bits
tem = Ncw * Lldpc * rate - Npld;
Nshrt = max(0, tem);       vNshrt = zeros(1, Ncw);

if( Nshrt > 0)
    Nspcw = floor( Nshrt / Ncw);
    Nsp1 = rem( Nshrt, Ncw); % set bit index (k-Nspcw-1 : k-1) to zero
    vNshrt(1: Nsp1) = Nspcw + 1;
    vNshrt(Nsp1+1 : Ncw) = Nspcw; % set bit index (k-Nspcw : k-1) to zero
end

vCwLen = Lldpc - vNshrt;

% d) Compute bit to be punctured
tem = (Ncw * Lldpc) - Navbits - Nshrt;
Npunc = max( 0, tem);

temA = 0.1 * Ncw * Lldpc * (1-rate);
temB = 1.2 * Npunc * (rate /(1-rate));
temC = 0.3 * Ncw * Lldpc *(1-rate);

if( ( (Npunc > temA) && (Nshrt < temB)) || (Npunc > temC))
    Navbits = Navbits + Ncbps;
    tem = (Ncw * Lldpc) - Navbits - Nshrt;
    Npunc = max( 0, tem);
end

Nppcw = floor( Npunc/ Ncw);   vNpunc = zeros(1, Ncw);
Nsym = Navbits / Ncbps;

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

ldpcPara.Lldpc = Lldpc;        ldpcPara.Ncw = Ncw;
ldpcPara.Nsym = Nsym;          ldpcPara.Ncbps = Ncbps;
ldpcPara.Navbits = Navbits;    ldpcPara.K0 = K0;
ldpcPara.rate = rate;

ldpcPara.Nshrt = Nshrt;        ldpcPara.Npunc = Npunc;
ldpcPara.Nrep = Nrep;

% the following vectors are 1-by-Ncw
ldpcPara.vNshrt = vNshrt;  % Nspcw for each codeword:
ldpcPara.vNpunc = vNpunc;     % Nppcw for each codeword
ldpcPara.vNrepInt = vNrepInt; % repeat number of the whole codeword
ldpcPara.vNrepRem = vNrepRem; % repeat number of bits in a codeword

ldpcPara.vCwLen = vCwLen;   % codeword length after discard shorten bits, punc or repeat

ldpcPara.FileIdx = FileIdx;
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
