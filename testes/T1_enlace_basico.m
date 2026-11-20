% T1_enlace_basico.m - Teste T1: enlace basico acustico com 10 rodadas.
% Cada gravacao bruta e decodificada DUAS vezes (com e sem pre-processamento),
% para que a comparacao use exatamente o mesmo sinal (pendencia do Marco 2).
%
% modo = 'acustico' : toca e grava (TRANSMISSAO ACUSTICA), salva sinal/t1_rbXXX_rN.wav
% modo = 'arquivo'  : decodifica de novo as gravacoes ja salvas
clear; close all; clc;
raiz = fileparts(fileparts(mfilename('fullpath')));
addpath(raiz, fullfile(raiz, 'funcoes'));
dir_res = fullfile(raiz, 'resultados'); if ~exist(dir_res, 'dir'), mkdir(dir_res); end
dir_sin = fullfile(raiz, 'sinal');      if ~exist(dir_sin, 'dir'), mkdir(dir_sin); end

modo      = 'acustico';
n_rodadas = 10;
t_pre = 1; t_pos = 1;

cfg = config_modem();
arq_log = fullfile(dir_res, sprintf('T1_enlace_basico_%s.txt', modo));
if exist(arq_log, 'file'), delete(arq_log); end
diary(arq_log);

bits_tx = texto2bits(cfg.msgA);
[ytx, quadro] = modem_tx_bits(bits_tx, cfg);
dur = length(ytx) / cfg.Fa;
fprintf('T1 - Enlace basico [TRANSMISSAO ACUSTICA, modo %s]\n', modo);
fprintf('Mensagem "%s" | RB = %d bps | quadro %d simbolos | %.2f s\n\n', cfg.msgA, cfg.RB, length(quadro), dur);

E = nan(2, n_rodadas); L = nan(2, n_rodadas); AV = nan(2, n_rodadas); M = cell(2, n_rodadas);
for r = 1:n_rodadas
    arq = fullfile(dir_sin, sprintf('t1_rb%d_r%d.wav', cfg.RB, r));
    if strcmp(modo, 'acustico')
        rec = audiorecorder(cfg.Fa, 16, 1);
        ply = audioplayer(ytx, cfg.Fa);
        record(rec); pause(t_pre); play(ply); pause(dur + t_pos); stop(rec);
        y = getaudiodata(rec, 'double');
        audiowrite(arq, y, cfg.Fa);
    else
        if ~exist(arq, 'file'), fprintf('Arquivo %s nao encontrado.\n', arq); break; end
        y = audioread(arq);
    end
    for p = 1:2           % 1 = com pre-processamento, 2 = sem
        [b, info] = modem_rx_bits(y, cfg, p == 1);
        nc = min(length(b), length(bits_tx));
        E(p, r) = sum(b(1:nc) ~= bits_tx(1:nc)) + (length(bits_tx) - nc);
        L(p, r) = info.l; AV(p, r) = info.aviso; M{p, r} = bits2texto(b);
    end
    fprintf('Rodada %2d (pico %.3f): COM pre-proc. "%s" %d erros | SEM pre-proc. "%s" %d erros\n', ...
            r, info.pico, M{1, r}, E(1, r), M{2, r}, E(2, r));
    if strcmp(modo, 'acustico'), pause(1); end
end

n = sum(~isnan(E(1, :)));
nb = length(bits_tx);
fprintf('\n%-22s %-14s %-12s %-16s %-12s\n', '', 'Erros medios', 'BER media', 'Tamanho certo', 'Avisos SFD');
rot = {'Com pre-processamento', 'Sem pre-processamento'};
for p = 1:2
    fprintf('%-22s %-14.2f %-12s %-16s %-12s\n', rot{p}, mean(E(p, 1:n)), ...
            sprintf('%.2f%%', 100*mean(E(p, 1:n))/nb), sprintf('%d/%d', sum(L(p, 1:n) == length(cfg.msgA)), n), ...
            sprintf('%d/%d', sum(AV(p, 1:n)), n));
end
diary off;
save(fullfile(dir_res, sprintf('T1_enlace_basico_%s.mat', modo)), 'E', 'L', 'AV', 'M', 'cfg');
