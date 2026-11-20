% comparacao_receptores.m - receptor_2 (original) x receptor_3 (com passa-baixas).
% Parte 1 [SIMULACAO]: quadro integrado (176 bits) com silencio de 0 a 79 amostras
%   antes do sinal (sem o corte do pre-processamento, para que o instante de inicio
%   realmente mude), sem ruido e com ruido. Mostra que o receptor_2 depende do
%   instante em que o sinal comeca em relacao a portadora.
% Parte 2 [TRANSMISSAO ACUSTICA]: decodifica de novo as gravacoes do Marco 2
%   (sinal/captura_rb100_rN.wav, mensagem "OLA") com os dois receptores.
clear; close all; clc;
raiz = fileparts(fileparts(mfilename('fullpath')));
addpath(raiz, fullfile(raiz, 'funcoes'));
dir_res = fullfile(raiz, 'resultados'); if ~exist(dir_res, 'dir'), mkdir(dir_res); end
arq_log = fullfile(dir_res, 'comparacao_receptores.txt');
if exist(arq_log, 'file'), delete(arq_log); end
diary(arq_log);

cfg = config_modem();
rng(2026);
recs = {'receptor_2', 'receptor_3'};

% ---------------- Parte 1: simulacao ----------------
tx = cadeia_tx(cfg);
ytx = modem_tx_bits(tx.bits, cfg);
offsets = 0:79;                 % 1 simbolo = Fa/RB = 80 amostras
% Obs.: com sinal PERFEITAMENTE limpo e inicio em amostra impar, a portadora chega
% defasada de 90 graus, que e um ponto de equilibrio instavel do Costas loop: sem
% nenhum ruido ele nao sai dali (nos dois receptores). Qualquer ruido minimo o tira
% desse ponto, e uma gravacao real sempre tem ruido; por isso o caso "quase sem
% ruido" usa SNR = 40 dB.
snrs = [40 10 5];
fprintf('Parte 1 [SIMULACAO] - quadro integrado de %d bits, %d posicoes de inicio\n', length(tx.bits), length(offsets));
fprintf('%-12s %-8s %-22s %-22s\n', 'Receptor', 'SNR', 'Quadros sem erro', 'BER media no quadro');
E = zeros(numel(recs), numel(snrs), numel(offsets));
for s = 1:numel(snrs)
    for ri = 1:numel(recs)
        cfg.receptor = recs{ri};
        for k = 1:numel(offsets)
            y = [zeros(offsets(k), 1); ytx; zeros(400, 1)];
            if isfinite(snrs(s))
                y = y + sqrt(mean(ytx.^2) / 10^(snrs(s)/10)) * randn(size(y));
            end
            b = modem_rx_bits(y, cfg, false);   % sem corte: o inicio fica onde foi posto
            nc = min(length(b), length(tx.bits));
            E(ri, s, k) = sum(b(1:nc) ~= tx.bits(1:nc)) + length(tx.bits) - nc;
        end
        e = squeeze(E(ri, s, :));
        fprintf('%-12s %-8s %-22s %-22s\n', recs{ri}, num2str(snrs(s)), ...
                sprintf('%d/%d', sum(e == 0), numel(e)), sprintf('%.2f%%', 100*mean(e)/length(tx.bits)));
    end
end

% ---------------- Parte 2: gravacoes acusticas do Marco 2 ----------------
fprintf('\nParte 2 [TRANSMISSAO ACUSTICA] - gravacoes do Marco 2 ("%s", 100 bps)\n', cfg.msgA);
bits_ok = texto2bits(cfg.msgA);
fprintf('%-26s %-22s %-22s\n', 'Arquivo', 'receptor_2', 'receptor_3');
for r = 1:20
    arq = fullfile(raiz, 'sinal', sprintf('captura_rb100_r%d.wav', r));
    if ~exist(arq, 'file'), break; end
    y = audioread(arq);
    out = cell(1, 2);
    for ri = 1:2
        cfg.receptor = recs{ri};
        b = modem_rx_bits(y, cfg, true);
        nc = min(length(b), length(bits_ok));
        e = sum(b(1:nc) ~= bits_ok(1:nc)) + length(bits_ok) - nc;
        out{ri} = sprintf('"%s" %d erros', bits2texto(b), e);
    end
    fprintf('%-26s %-22s %-22s\n', sprintf('captura_rb100_r%d.wav', r), out{1}, out{2});
end
diary off;

% Figura: erros x instante de inicio (SNR = 40 dB)
fig = figure('Position', [100 100 900 350], 'Visible', 'off', 'Color', 'w');
try, theme(fig, 'light'); catch, end
plot(offsets, squeeze(E(1, 1, :)), 'r.-', offsets, squeeze(E(2, 1, :)), 'b.-'); grid on;
xlabel('Amostras de silencio antes do sinal');
ylabel(sprintf('Erros em %d bits', length(tx.bits)));
legend('receptor\_2 (original)', 'receptor\_3 (com passa-baixas)', 'Location', 'best');
title('SIMULACAO (SNR = 40 dB): erros conforme o instante de inicio do sinal');
saveas(fig, fullfile(dir_res, 'comparacao_receptores.png'));
close(fig);
