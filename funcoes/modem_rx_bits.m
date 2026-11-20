function [bits, info] = modem_rx_bits(y, cfg, usar_preproc)
% modem_rx_bits - Recebe um sinal de audio e devolve os bits de dados do quadro,
% usando o receptor escolhido em cfg.receptor (receptor_2.m original ou
% receptor_3.m, que e o receptor_2 com um filtro passa-baixas apos a demodulacao).
%   usar_preproc : true (padrao) aplica normalizacao + corte do silencio (Marco 2)
% Saida:
%   bits        : bits de dados (l*8 bits, LSB primeiro em cada byte)
%   info.l      : tamanho lido no cabecalho (bytes)
%   info.aviso  : true se o receptor avisou "Muitos erros" (SFD < 90%)
%   info.pico   : pico do sinal antes da normalizacao
%   info.falhou : true se o receptor gerou erro (quadro nao encontrado)
if nargin < 3
    usar_preproc = true;
end
y = y(:, 1);
info.pico = max(abs(y));
if usar_preproc
    y = y / max(abs(y));
    i0 = find(abs(y) > cfg.pre_limiar, 1);
    if isempty(i0), i0 = 1; end
    y = y(max(1, i0 - cfg.pre_margem):end);
end
info.l = 0; info.aviso = false; info.falhou = false; bits = [];
try
    fr = str2func(cfg.receptor);
    txt = evalc('[m, l] = fr(y, cfg.RB, cfg.Fp, cfg.Fa);');
    bits = double(m(:)');
    info.l = l;
    info.aviso = ~isempty(strfind(txt, 'Muitos erros')); %#ok<STREMP>
catch
    info.falhou = true;
end
end
