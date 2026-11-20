function c = hamming74_codifica(bits)
% hamming74_codifica - Codifica cada grupo de 4 bits em uma palavra de 7 bits.
% Ordem da palavra (posicoes 1..7):  [p1 p2 d1 p3 d2 d3 d4]
%   p1 = d1^d2^d4   (cobre posicoes 1,3,5,7)
%   p2 = d1^d3^d4   (cobre posicoes 2,3,6,7)
%   p3 = d2^d3^d4   (cobre posicoes 4,5,6,7)
% Assim a sindrome no receptor da diretamente a posicao do bit errado.
bits = double(bits(:)');
if mod(length(bits), 4) ~= 0
    error('hamming74_codifica: o numero de bits deve ser multiplo de 4.');
end
D = reshape(bits, 4, []);          % uma coluna por palavra
d1 = D(1,:); d2 = D(2,:); d3 = D(3,:); d4 = D(4,:);
p1 = mod(d1 + d2 + d4, 2);
p2 = mod(d1 + d3 + d4, 2);
p3 = mod(d2 + d3 + d4, 2);
C = [p1; p2; d1; p3; d2; d3; d4];
c = C(:)';
end
