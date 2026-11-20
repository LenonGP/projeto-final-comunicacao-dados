% T6_integrado_modem.m - Teste T6: sistema integrado passando pelo modem.
% TX: fluxos -> CRC-8 -> Hamming(7,4) -> TDM -> modem (BPSK)
% RX: modem -> demux TDM -> Hamming -> CRC -> fluxos
%
% modo = 'acustico'  : toca no alto-falante e grava no microfone (TRANSMISSAO ACUSTICA)
% modo = 'simulacao' : o sinal gerado vai direto ao receptor, com ruido opcional (SIMULACAO)
% modo = 'arquivo'   : decodifica de novo as gravacoes salvas em sinal/integrado_rbXXX_rN.wav
clear; close all; clc;
raiz = fileparts(fileparts(mfilename('fullpath')));
addpath(raiz, fullfile(raiz, 'funcoes'));
dir_res = fullfile(raiz, 'resultados'); if ~exist(dir_res, 'dir'), mkdir(dir_res); end
dir_sin = fullfile(raiz, 'sinal');      if ~exist(dir_sin, 'dir'), mkdir(dir_sin); end

% ------------------------- Configuracao do teste -------------------------
modo      = 'acustico';  % 'acustico' | 'simulacao' | 'arquivo'
n_rodadas = 10;
snr_db    = Inf;         % so no modo 'simulacao' (Inf = sem ruido)
t_pre     = 1;           % s de gravacao antes do sinal (modo acustico)
t_pos     = 1;           % s de gravacao depois do sinal (modo acustico)
% -------------------------------------------------------------------------

cfg = config_modem();
rng(2026);
sufixo = modo; if strcmp(modo, 'simulacao') && isfinite(snr_db), sufixo = sprintf('simulacao_snr%g', snr_db); end
arq_log = fullfile(dir_res, ['T6_integrado_' sufixo '.txt']);
if exist(arq_log, 'file'), delete(arq_log); end
diary(arq_log);

tx = cadeia_tx(cfg);
n_ham = length(tx.ham{1});
[ytx, quadro] = modem_tx_bits(tx.bits, cfg);
dur = length(ytx) / cfg.Fa;

switch modo
    case 'acustico',  rotulo = 'TRANSMISSAO ACUSTICA';
    case 'simulacao', rotulo = sprintf('SIMULACAO (sinal direto ao receptor, SNR = %g dB)', snr_db);
    case 'arquivo',   rotulo = 'TRANSMISSAO ACUSTICA (gravacoes salvas, decodificadas de novo)';
end
fprintf('T6 - Sistema integrado pelo modem [%s]\n', rotulo);
fprintf('Fluxo A = "%s" | Fluxo B = "%s" | RB = %d bps | Fp = %d Hz | Fa = %d Hz\n', ...
        tx.msgs{1}, tx.msgs{2}, cfg.RB, cfg.Fp, cfg.Fa);
fprintf('Carga TDM: %d bits (%d bytes) | quadro do modem: %d simbolos | sinal: %.2f s\n\n', ...
        length(tx.bits), length(tx.bits)/8, length(quadro), dur);

R = struct('l', {}, 'aviso', {}, 'eTDM', {}, 'eA_antes', {}, 'eB_antes', {}, ...
           'eA_dep', {}, 'eB_dep', {}, 'corrA', {}, 'corrB', {}, 'crcA', {}, 'crcB', {}, ...
           'msgA', {}, 'msgB', {});
for r = 1:n_rodadas
    arq = fullfile(dir_sin, sprintf('integrado_rb%d_r%d.wav', cfg.RB, r));
    switch modo
        case 'acustico'
            rec = audiorecorder(cfg.Fa, 16, 1);
            ply = audioplayer(ytx, cfg.Fa);
            record(rec); pause(t_pre);
            play(ply);   pause(dur + t_pos);
            stop(rec);
            y = getaudiodata(rec, 'double');
            audiowrite(arq, y, cfg.Fa);
        case 'simulacao'
            y = [zeros(round(0.2*cfg.Fa) + randi(80), 1); ytx; zeros(round(0.2*cfg.Fa), 1)];  % inicio sorteado
            if isfinite(snr_db)
                Ps = mean(ytx.^2);
                y = y + sqrt(Ps / 10^(snr_db/10)) * randn(size(y));
            end
        case 'arquivo'
            if ~exist(arq, 'file')
                fprintf('Rodada %d: arquivo %s nao encontrado, parando.\n', r, arq);
                break;
            end
            y = audioread(arq);
    end

    [bits_rx, info] = modem_rx_bits(y, cfg, true);
    rx = cadeia_rx(bits_rx, cfg, tx.n_quadros, n_ham);

    % erros no quadro TDM inteiro (bits que nao chegaram contam como erro)
    nc = min(length(bits_rx), length(tx.bits));
    eTDM = sum(bits_rx(1:nc) ~= tx.bits(1:nc)) + (length(tx.bits) - nc);

    R(r).l = info.l; R(r).aviso = info.aviso; R(r).eTDM = eTDM;
    R(r).eA_antes = sum(rx.ham{1} ~= tx.ham{1});   R(r).eB_antes = sum(rx.ham{2} ~= tx.ham{2});
    R(r).eA_dep   = sum(rx.dados{1} ~= tx.dados{1}); R(r).eB_dep = sum(rx.dados{2} ~= tx.dados{2});
    R(r).corrA = rx.n_corr(1); R(r).corrB = rx.n_corr(2);
    R(r).crcA = rx.crc_ok(1);  R(r).crcB = rx.crc_ok(2);
    R(r).msgA = rx.msg{1};     R(r).msgB = rx.msg{2};
    fprintf('Rodada %2d: pico %.3f | l = %2d | aviso SFD: %-3s | erros no quadro TDM: %3d\n', ...
            r, info.pico, info.l, ternario(info.aviso, 'sim', 'nao'), eTDM);
    fprintf('           A: "%s" erros %2d/%d -> %2d/%d apos Hamming (%d corr.), CRC %s\n', ...
            rx.msg{1}, R(r).eA_antes, n_ham, R(r).eA_dep, length(tx.dados{1}), rx.n_corr(1), ternario(rx.crc_ok(1), 'valido', 'INVALIDO'));
    fprintf('           B: "%s" erros %2d/%d -> %2d/%d apos Hamming (%d corr.), CRC %s\n', ...
            rx.msg{2}, R(r).eB_antes, n_ham, R(r).eB_dep, length(tx.dados{2}), rx.n_corr(2), ternario(rx.crc_ok(2), 'valido', 'INVALIDO'));
    if strcmp(modo, 'acustico'), pause(1); end
    y_ult = y; rx_ult = rx;
end

% ------------------------------- Resumo ----------------------------------
n = numel(R);
if n == 0, diary off; return; end
nd = length(tx.dados{1});
fprintf('\n=================== RESUMO (%s) ===================\n', rotulo);
fprintf('Rodadas: %d\n', n);
fprintf('%-8s %-18s %-18s %-14s %-12s\n', 'Fluxo', 'BER antes (Ham.)', 'BER depois', 'Msg correta', 'CRC valido');
fprintf('%-8s %-18s %-18s %-14s %-12s\n', 'A', ...
        sprintf('%.2f%%', 100*sum([R.eA_antes])/(n*n_ham)), sprintf('%.2f%%', 100*sum([R.eA_dep])/(n*nd)), ...
        sprintf('%d/%d', sum([R.eA_dep] == 0), n), sprintf('%d/%d', sum([R.crcA]), n));
fprintf('%-8s %-18s %-18s %-14s %-12s\n', 'B', ...
        sprintf('%.2f%%', 100*sum([R.eB_antes])/(n*n_ham)), sprintf('%.2f%%', 100*sum([R.eB_dep])/(n*nd)), ...
        sprintf('%d/%d', sum([R.eB_dep] == 0), n), sprintf('%d/%d', sum([R.crcB]), n));
falso_ok = sum(([R.crcA] & [R.eA_dep] > 0) | ([R.crcB] & [R.eB_dep] > 0));
fprintf('Casos com CRC valido mas mensagem errada (nao detectados): %d\n', falso_ok);
fprintf('==========================================================\n');
diary off;
save(fullfile(dir_res, ['T6_integrado_' sufixo '.mat']), 'R', 'cfg', 'modo', 'snr_db');

% ------------------------- Figura da ultima rodada -----------------------
fig = figure('Position', [100 100 1000 700], 'Visible', 'off', 'Color', 'w');
try, theme(fig, 'light'); catch, end
subplot(3,1,1);
plot((0:length(y_ult)-1)/cfg.Fa, y_ult); grid on;
title(sprintf('T6 [%s] - sinal recebido, rodada %d', rotulo, n)); xlabel('Tempo (s)');
for f = 1:2
    subplot(3,1,1+f);
    d_tx = tx.dados{f}; d_rx = rx_ult.dados{f};
    stem(1:length(d_tx), d_tx, 'b', 'filled'); hold on;
    stem(1:length(d_rx), d_rx, 'r--', 'LineWidth', 1.2);
    ylim([-0.2 1.3]); grid on;
    legend('TX', 'RX', 'Location', 'eastoutside');
    title(sprintf('Fluxo %s: TX "%s" | RX "%s" | erros = %d | CRC %s', char('A'+f-1), tx.msgs{f}, ...
          rx_ult.msg{f}, sum(d_rx ~= d_tx), ternario(rx_ult.crc_ok(f), 'valido', 'invalido')));
end
saveas(fig, fullfile(dir_res, ['T6_integrado_' sufixo '.png']));
close(fig);
