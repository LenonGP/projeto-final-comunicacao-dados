function [y, quadro] = modem_tx_bits(bits, cfg)
% modem_tx_bits - Envia uma sequencia de bits qualquer pelo modem fornecido,
% sem alterar o transmissor.m: os bits sao agrupados em bytes (LSB primeiro)
% e passados como "caracteres" (valores 0..255). O transmissor monta o quadro
% PRE | SFD | tamanho | dados | PRE normalmente.
%   y      : sinal BPSK normalizado (coluna), pronto para tocar
%   quadro : simbolos do quadro do modem
if mod(length(bits), 8) ~= 0
    warning('modem_tx_bits: %d bits nao e multiplo de 8; completando com zeros.', length(bits));
end
bytes = bits2bytes(bits);
if length(bytes) > 255
    error('modem_tx_bits: o campo de tamanho do modem limita o quadro a 255 bytes.');
end
evalc('[y, quadro] = transmissor(char(bytes), cfg.RB, cfg.Fp, cfg.Fa);');  % evalc so silencia o disp
y = y(:) / max(abs(y));
end
