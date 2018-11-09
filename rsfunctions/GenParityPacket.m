function packetparity = GenParityPacket(rsEncoder, data_msg)

packetlength = size(data_msg,1);
packetdata = data_msg;

N = rsEncoder.CodewordLength;
K = rsEncoder.MessageLength;
S = rsEncoder.ShortMessageLength;

num_short_words = ceil(packetlength/S);
infoRS = zeros(S, num_short_words);

for i = 1:num_short_words - 1
    infoRS(:,i) = packetdata((i-1)*S+1:i*S);
end

% cover the case of S dividing packetlength exactly
if mod(packetlength,S)==0
    infoRS(:,num_short_words) =...
        packetdata((num_short_words-1)*S+1:num_short_words*S);
end

% if there are remaining bytes, less than S, zero pad
if floor(packetlength/S) ~= num_short_words
    infoRS(:,num_short_words)=zeros(S,1);
    infoRS(1:mod(packetlength,S),num_short_words)...
        =packetdata((num_short_words-1)*S+1:end);
end

% RS encoder requires a column vector S,1, and returns a column vector N-numPuncs-K+S
% (no puncturing used here)
encData = zeros(N-K+S,num_short_words);
for i=1:num_short_words
    encData(:,i) = rsEncoder(infoRS(:,i)); % data
end

% Parity symbols are located as last N-K symbols
% of each column in encData. Generate parity packet
% as a column vector of length 3*(N-K)
packetparity = zeros(num_short_words*(N-K),1);
for i=1:num_short_words
    packetparity((i-1)*(N-K)+1:i*(N-K))=encData(S+1:N-K+S,i);
end
