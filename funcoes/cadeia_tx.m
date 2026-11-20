function tx = cadeia_tx(cfg, msgs)
% cadeia_tx - Ponto de entrada do TRANSMISSOR (parte digital).
% Ordem dos blocos (Marco 1): fluxo -> CRC-8 -> Hamming(7,4) -> TDM.
%   msgs : cell com o texto de cada fluxo (padrao: {cfg.msgA, cfg.msgB})
% Saida (struct):
%   tx.dados{f}   bits de dados do fluxo f
%   tx.crc{f}     dados + CRC-8
%   tx.ham{f}     palavras Hamming(7,4)
%   tx.bits       sequencia multiplexada entregue ao modem
%   tx.n_quadros  numero de quadros TDM
if nargin < 2
    msgs = {cfg.msgA, cfg.msgB};
end
N = numel(msgs);
tx.msgs = msgs;
tx.dados = cell(1, N); tx.crc = cell(1, N); tx.ham = cell(1, N);
for f = 1:N
    tx.dados{f} = texto2bits(msgs{f});
    tx.crc{f}   = crc8_anexa(tx.dados{f}, cfg.crc_poli);
    tx.ham{f}   = hamming74_codifica(tx.crc{f});
end
[tx.bits, tx.n_quadros] = tdm_mux(tx.ham, cfg.tdm_slot, cfg.tdm_sync);
end
