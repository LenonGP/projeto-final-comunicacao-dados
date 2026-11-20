function [ok, dados, resto] = crc8_verifica(cw, poli)
% crc8_verifica - Receptor: divide a sequencia recebida (dados + CRC) por G(x).
%   ok    = true se o resto for zero (nenhum erro detectado)
%   dados = sequencia sem os 8 bits de CRC
%   resto = resto da divisao (8 bits); diferente de zero => erro detectado
if nargin < 2
    poli = [1 0 0 0 0 0 1 1 1];
end
cw = double(cw(:)');
resto = crc8_calc(cw, poli);
ok = ~any(resto);
dados = cw(1:end-8);
end
