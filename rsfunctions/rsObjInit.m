function [rsEncoder, rsDecoder ] = rsObjInit(N, K, S, gfdeg)

rsEncoder = comm.RSEncoder(N, K, 'BitInput', false);
rsDecoder = comm.RSDecoder(N, K, 'BitInput', false, 'ErasuresInputPort', false);

% Set the shortened message length values
if (S < K)
    rsEncoder.ShortMessageLength = S;
    rsDecoder.ShortMessageLength = S;
end

rsEncoder.PrimitivePolynomialSource = 'Property';
rsEncoder.PrimitivePolynomial = de2bi(primpoly(gfdeg, 'nodisplay'), 'left-msb');

rsDecoder.PrimitivePolynomialSource = 'Property';
rsDecoder.PrimitivePolynomial = de2bi(primpoly(gfdeg, 'nodisplay'), 'left-msb');
