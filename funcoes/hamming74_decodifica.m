function [bits, n_corr, pos_corr] = hamming74_decodifica(c)
% hamming74_decodifica - Corrige ate 1 bit por palavra de 7 bits e devolve os dados.
%   bits     = dados recuperados (4 bits por palavra)
%   n_corr   = numero de palavras em que um bit foi corrigido
%   pos_corr = posicao (1..7) corrigida em cada palavra (0 = sindrome nula)
% Limite: 1 erro por palavra. Com 2 erros na mesma palavra a sindrome aponta
% para uma terceira posicao e o dado sai errado (o CRC deve sinalizar).
c = double(c(:)');
if mod(length(c), 7) ~= 0
    error('hamming74_decodifica: o numero de bits deve ser multiplo de 7.');
end
C = reshape(c, 7, []);
s1 = mod(C(1,:) + C(3,:) + C(5,:) + C(7,:), 2);
s2 = mod(C(2,:) + C(3,:) + C(6,:) + C(7,:), 2);
s3 = mod(C(4,:) + C(5,:) + C(6,:) + C(7,:), 2);
pos_corr = s1 + 2*s2 + 4*s3;       % posicao do bit errado (0 = nenhum)
for k = find(pos_corr > 0)
    C(pos_corr(k), k) = 1 - C(pos_corr(k), k);
end
n_corr = sum(pos_corr > 0);
D = C([3 5 6 7], :);
bits = D(:)';
end
