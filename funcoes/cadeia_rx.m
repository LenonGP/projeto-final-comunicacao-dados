function rx = cadeia_rx(bits, cfg, n_quadros, n_bits_ham)
% cadeia_rx - Ponto de entrada do RECEPTOR (parte digital).
% Ordem dos blocos (Marco 1): demux TDM -> Hamming(7,4) -> verificacao CRC-8.
%   bits       : sequencia recebida do modem (ou com erros injetados)
%   n_quadros  : numero de quadros TDM esperados
%   n_bits_ham : bits Hamming de cada fluxo (para descartar o enchimento)
% Saida (struct), para cada fluxo f:
%   rx.ham{f}      bits do slot do fluxo f (antes da correcao)
%   rx.crc{f}      dados + CRC apos a correcao
%   rx.dados{f}    dados recuperados (sem CRC)
%   rx.msg{f}      texto recuperado
%   rx.n_corr(f)   palavras corrigidas pelo Hamming
%   rx.crc_ok(f)   resultado da verificacao do CRC
%   rx.tdm         informacoes do sincronismo TDM
N = cfg.n_fluxos;
[fl, rx.tdm] = tdm_demux(bits, N, cfg.tdm_slot, n_quadros, cfg.tdm_sync);
rx.ham = cell(1, N); rx.crc = cell(1, N); rx.dados = cell(1, N); rx.msg = cell(1, N);
rx.n_corr = zeros(1, N); rx.crc_ok = false(1, N);
for f = 1:N
    rx.ham{f} = fl{f}(1:n_bits_ham);
    [rx.crc{f}, rx.n_corr(f)] = hamming74_decodifica(rx.ham{f});
    [rx.crc_ok(f), rx.dados{f}] = crc8_verifica(rx.crc{f}, cfg.crc_poli);
    rx.msg{f} = bits2texto(rx.dados{f});
end
end
