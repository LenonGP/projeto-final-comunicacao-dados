function txt = bits2texto(bits)
% bits2texto - Converte bits (LSB primeiro) em texto. Caracteres nao
% imprimiveis viram '?'. Bits que nao completam um byte sao ignorados.
n = floor(length(bits) / 8);
if n == 0
    txt = '';
    return;
end
v = bits2bytes(bits(1:8*n));
v(v < 32 | v > 126) = double('?');
txt = char(v);
end
