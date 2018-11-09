function RSpacket= RSDecodePacket(rsDecoder, demodpacket, demodparity)

%% retrieve parameters from decoder object and inputs
S = rsDecoder.ShortMessageLength;
N = rsDecoder.CodewordLength;
K = rsDecoder.MessageLength;

packetlength = size(demodpacket,1);
num_short_words = ceil(packetlength/S);

%% construct input to RS decoder from channel data
% compose inputs to RS decoder
demodRS = zeros(N-K+S, num_short_words);
for i=1:num_short_words-1
    demodRS(1:S,i) = demodpacket((i-1)*S+1:i*S);
    demodRS(S+1:N-K+S,i) = demodparity((i-1)*(N-K)+1:i*(N-K));
end

% case of S dividing packetlength
if mod(packetlength,S)==0
    demodRS(1:S,num_short_words) = demodpacket((num_short_words-1)*S+1:num_short_words*S);
    demodRS(S+1:N-K+S,num_short_words) = demodparity((num_short_words-1)*(N-K)+1:num_short_words*(N-K));
end

if floor(packetlength/S) ~= num_short_words
    demodRS(1:mod(packetlength,S),num_short_words)= ...
        demodpacket((num_short_words-1)*S+1:packetlength);
    demodRS(S+1:N-K+S,num_short_words)= ...
        demodparity((num_short_words-1)*(N-K)+1:...
        num_short_words*(N-K));
end

%% RS decode packet
for i=1:num_short_words
    estData(:,i) = rsDecoder(demodRS(:,i));
end

% reconstruct packet from RS decoder output
RSpacket = zeros(packetlength,1);
for i=1:num_short_words-1
    RSpacket((i-1)*S+1:i*S,1)= estData(:,i);
end
%fix
if mod(packetlength,S)==0
    RSpacket((num_short_words-1)*S+1:num_short_words*S,1) = estData(:,num_short_words);
end
if floor(packetlength/S) ~= num_short_words
    RSpacket((num_short_words-1)*S+1:packetlength,1)= estData(1:mod(packetlength,S),num_short_words);
end

