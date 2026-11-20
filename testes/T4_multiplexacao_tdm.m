% T4_multiplexacao_tdm.m - Teste T4: TDM isolado, sem CRC nem Hamming (SOFTWARE)
clear; close all; clc;
raiz = fileparts(fileparts(mfilename('fullpath')));
addpath(raiz, fullfile(raiz, 'funcoes'));
dir_res = fullfile(raiz, 'resultados'); if ~exist(dir_res, 'dir'), mkdir(dir_res); end
arq_log = fullfile(dir_res, 'T4_multiplexacao_tdm.txt');
if exist(arq_log, 'file'), delete(arq_log); end
diary(arq_log);

cfg = config_modem();
rng(2026);
fprintf('T4 - Multiplexacao TDM isolada [teste em SOFTWARE]\n');
fprintf('Quadro = [SYNC %s | slot A (%d bits) | slot B (%d bits)]\n\n', ...
        sprintf('%d', cfg.tdm_sync), cfg.tdm_slot, cfg.tdm_slot);

A = texto2bits(cfg.msgA);
B = texto2bits(cfg.msgB);
nA = length(A); nB = length(B);
[mux, nq] = tdm_mux({A, B}, cfg.tdm_slot, cfg.tdm_sync);
fprintf('Fluxo A = "%s": %s\n', cfg.msgA, sprintf('%d', A));
fprintf('Fluxo B = "%s": %s\n', cfg.msgB, sprintf('%d', B));
fprintf('Quadros TDM: %d de %d bits -> %d bits multiplexados\n\n', nq, length(mux)/nq, length(mux));

% (a) sem deslocamento
[fl, info] = tdm_demux(mux, 2, cfg.tdm_slot, nq, cfg.tdm_sync);
eA = sum(fl{1}(1:nA) ~= A); eB = sum(fl{2}(1:nB) ~= B);
fprintf('(a) Sem deslocamento: offset = %d | erros A = %d | erros B = %d | A = "%s" | B = "%s"\n', ...
        info.offset, eA, eB, bits2texto(fl{1}(1:nA)), bits2texto(fl{2}(1:nB)));
ok_a = eA == 0 && eB == 0 && info.offset == 0;

% (b) bits de lixo antes do primeiro quadro (0 a 40 bits aleatorios)
ok_b = true;
fprintf('(b) Lixo antes do primeiro quadro:\n');
for n_lixo = [1 5 13 22 40]
    rx = [randi([0 1], 1, n_lixo) mux randi([0 1], 1, 10)];
    [fl, info] = tdm_demux(rx, 2, cfg.tdm_slot, nq, cfg.tdm_sync);
    eA = sum(fl{1}(1:nA) ~= A); eB = sum(fl{2}(1:nB) ~= B);
    fprintf('    %2d bits de lixo -> offset encontrado = %2d | erros A = %d | erros B = %d\n', ...
            n_lixo, info.offset, eA, eB);
    ok_b = ok_b && info.offset == n_lixo && eA == 0 && eB == 0;
end

% (c) identificacao dos fluxos: o slot B nao contem A (e vice-versa)
[fl, ~] = tdm_demux(mux, 2, cfg.tdm_slot, nq, cfg.tdm_sync);
cruzA = sum(fl{2}(1:nA) ~= A);
cruzB = sum(fl{1}(1:nB) ~= B);
fprintf('(c) Slot B comparado com A: %d bits diferentes; slot A comparado com B: %d bits diferentes\n', cruzA, cruzB);
ok_c = cruzA > 0 && cruzB > 0;

passou = ok_a && ok_b && ok_c;
fprintf('\nResultado T4: %s\n', ternario(passou, 'PASSOU', 'FALHOU'));
diary off;

% --- Figura: estrutura dos quadros (cores = sync / A / B / enchimento) ---
Lq = length(cfg.tdm_sync) + 2*cfg.tdm_slot;
tipo = zeros(1, length(mux));
for q = 1:nq
    b0 = (q-1)*Lq;
    tipo(b0 + (1:8)) = 1;
    for j = 1:cfg.tdm_slot
        k = (q-1)*cfg.tdm_slot + j;
        tipo(b0 + 8 + j) = 2 + 2*(k > nA);
        tipo(b0 + 8 + cfg.tdm_slot + j) = 3 + (k > nB);
    end
end
fig = figure('Position', [100 100 1100 300], 'Visible', 'off', 'Color', 'w');
try, theme(fig, 'light'); catch, end
cores = [0.6 0.6 0.6; 0.15 0.45 0.85; 0.9 0.45 0.1; 0.92 0.92 0.92];
for i = 1:length(mux)
    rectangle('Position', [i-1 0 1 1], 'FaceColor', cores(min(tipo(i), 4), :), 'EdgeColor', 'w');
    text(i-0.5, 0.5, num2str(mux(i)), 'HorizontalAlignment', 'center', 'FontSize', 7);
end
for q = 1:nq
    text((q-1)*Lq + Lq/2, 1.25, sprintf('Quadro %d', q), 'HorizontalAlignment', 'center', 'FontSize', 8);
end
axis([0 length(mux) -0.2 1.5]); axis off;
title(sprintf('TDM: cinza = SYNC, azul = fluxo A ("%s"), laranja = fluxo B ("%s"), claro = enchimento', cfg.msgA, cfg.msgB));
saveas(fig, fullfile(dir_res, 'T4_quadros_tdm.png'));
close(fig);
