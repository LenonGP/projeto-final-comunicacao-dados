function bits = texto2bits(txt)
% texto2bits - Converte texto em bits, 8 bits por caractere, bit menos
% significativo primeiro (mesma ordem do de2bi usado no transmissor.m).
bits = bytes2bits(double(char(txt)));
end
