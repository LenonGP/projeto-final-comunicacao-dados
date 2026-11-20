function cw = crc8_anexa(bits, poli)
% crc8_anexa - Transmissor: anexa os 8 bits de CRC ao final dos dados.
if nargin < 2
    poli = [1 0 0 0 0 0 1 1 1];
end
bits = double(bits(:)');
cw = [bits crc8_calc(bits, poli)];
end
