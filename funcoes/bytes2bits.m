function bits = bytes2bits(bytes)
% bytes2bits - Vetor de bytes (0..255) -> vetor linha de bits, LSB primeiro.
bytes = double(bytes(:)');
M = zeros(8, length(bytes));
for k = 1:8
    M(k, :) = mod(floor(bytes / 2^(k-1)), 2);
end
bits = M(:)';
end
