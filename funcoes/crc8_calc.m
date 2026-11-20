function r = crc8_calc(bits, poli)
% crc8_calc - Resto da divisao de M(x)*x^8 pelo polinomio gerador G(x), em GF(2).
%   r = crc8_calc(bits)        usa G(x) = x^8 + x^2 + x + 1 (0x07)
%   r = crc8_calc(bits, poli)  poli = coeficientes de x^8 ate x^0 (9 elementos)
% Saida: 8 bits, do coeficiente de x^7 ate x^0.
% Implementacao bit a bit (registrador de deslocamento), sem toolbox.
if nargin < 2
    poli = [1 0 0 0 0 0 1 1 1];
end
g = poli(2:end);          % termos abaixo de x^8
reg = zeros(1, 8);
for b = double(bits(:)')
    fb = xor(reg(1), b);  % bit que "sai" do registrador XOR bit de entrada
    reg = [reg(2:end) 0];
    if fb
        reg = xor(reg, g);
    end
end
r = double(reg);
end
