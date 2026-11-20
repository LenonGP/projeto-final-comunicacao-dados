function bytes = bits2bytes(bits)
% bits2bytes - Vetor de bits (LSB primeiro) -> vetor linha de bytes.
% Completa com zeros ate um multiplo de 8.
bits = double(bits(:)');
bits = [bits zeros(1, mod(-length(bits), 8))];
M = reshape(bits, 8, []);
bytes = (2.^(0:7)) * M;
end
