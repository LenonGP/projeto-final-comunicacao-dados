function bits = injeta_erros(bits, pos)
% injeta_erros - Inverte os bits nas posicoes indicadas (erro controlado).
%   bits = injeta_erros(bits, [3 10])  inverte os bits 3 e 10.
% Para sorteios reprodutiveis, use rng(semente) antes de escolher as posicoes.
bits = double(bits);
pos = pos(pos >= 1 & pos <= length(bits));
bits(pos) = 1 - bits(pos);
end
