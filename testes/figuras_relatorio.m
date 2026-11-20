function figuras_relatorio()
% figuras_relatorio - Figuras ilustrativas para o relatorio (salvas em resultados/).
% Usa as gravacoes ja salvas em sinal/ (T1 e T6 acusticos); nao grava nada novo.
% Escrito como funcao (e nao script) para que as funcoes auxiliares no fim do
% arquivo funcionem tambem no Octave. Uso: run('testes/figuras_relatorio.m')
close all;
raiz = fileparts(fileparts(mfilename('fullpath')));
addpath(raiz, fullfile(raiz, 'funcoes'));
dir_res = fullfile(raiz, 'resultados'); if ~exist(dir_res, 'dir'), mkdir(dir_res); end
cfg = config_modem();
tx = cadeia_tx(cfg);
ytx = modem_tx_bits(tx.bits, cfg);
st = cfg.Fa / cfg.RB;                     % amostras por simbolo

% ---------- 1) Sinal transmitido e espectro (TX x gravacao acustica) ----------
y_ac = audioread(fullfile(raiz, 'sinal', sprintf('integrado_rb%d_r1.wav', cfg.RB)));
fig = nova_figura([900 600]);
subplot(2,1,1);
plot((0:length(ytx)-1)/cfg.Fa, ytx); grid on; xlim([0 length(ytx)/cfg.Fa]);
title('Sinal BPSK transmitido (quadro integrado, 296 simbolos)'); xlabel('Tempo (s)'); ylabel('Amplitude');
subplot(2,1,2);
[f1, P1] = espectro(ytx, cfg.Fa); [f2, P2] = espectro(y_ac, cfg.Fa);
plot(f1, P1, 'b', f2, P2, 'r'); grid on; xlim([0 cfg.Fa/2]); ylim([-80 5]);
legend('Transmitido', 'Gravado no microfone (T6, rodada 1)', 'Location', 'northeast');
title(sprintf('Espectro: energia concentrada em torno de F_p = %d Hz', cfg.Fp));
xlabel('Frequencia (Hz)'); ylabel('Magnitude (dB, normalizada)');
salva(fig, fullfile(dir_res, 'fig_sinal_espectro.png'));

% ---------- 2) Por que o filtro passa-baixas: amostras apos a demodulacao ----------
% Sinal que comeca 1 amostra "atrasado": a portadora chega com fase de 90 graus
% em relacao a t = 0. Mesmo com a fase estimada corretamente, a componente em
% 2*Fp = Fa/2 faz as amostras alternarem entre ~0 e o valor do simbolo.
y = [0; ytx];
n = (0:length(y)-1)';
d = y .* cos(2*pi*cfg.Fp*n/cfg.Fa - pi/2);          % demodulacao com a fase certa
h = fir1(32, 1.5*cfg.RB/(cfg.Fa/2));
d_pb = conv(d, h(:), 'same');
janela = (132*st):(133.5*st);                        % 1,5 simbolo no meio da carga
fig = nova_figura([900 380]);
stem(janela/cfg.Fa*1000, d(janela+1), 'Color', [0.8 0.3 0.3], 'Marker', '.'); hold on;
plot(janela/cfg.Fa*1000, d_pb(janela+1), 'b', 'LineWidth', 2); grid on;
legend('Demodulado, sem filtro (receptor\_2)', 'Com passa-baixas (receptor\_3)', 'Location', 'southeast');
title('Amostras apos a demodulacao: sem filtro, elas alternam entre ~0 e o valor do simbolo');
xlabel('Tempo (ms)'); ylabel('Amplitude');
salva(fig, fullfile(dir_res, 'fig_demodulacao_pb.png'));

% ---------- 3) Pre-processamento sobre uma gravacao do T1 ----------
y1 = audioread(fullfile(raiz, 'sinal', sprintf('t1_rb%d_r1.wav', cfg.RB)));
y1 = y1(:, 1);
yn = y1 / max(abs(y1));
i0 = find(abs(yn) > cfg.pre_limiar, 1);
ic = max(1, i0 - cfg.pre_margem);
fig = nova_figura([900 500]);
subplot(2,1,1);
plot((0:length(y1)-1)/cfg.Fa, y1); hold on; grid on;
yl = ylim; plot([ic ic]/cfg.Fa, yl, 'r--', 'LineWidth', 1.5);
title(sprintf('Gravacao bruta do T1 (rodada 1): pico = %.3f; linha = ponto de corte', max(abs(y1))));
xlabel('Tempo (s)'); ylabel('Amplitude');
subplot(2,1,2);
plot((0:length(yn)-ic)/cfg.Fa, yn(ic:end)); grid on; ylim([-1.1 1.1]);
title('Apos o pre-processamento: normalizada pelo pico e sem o silencio inicial');
xlabel('Tempo (s)'); ylabel('Amplitude');
salva(fig, fullfile(dir_res, 'fig_preprocessamento.png'));

% ---------- 4) T5: onde os erros foram injetados no quadro TDM ----------
N = cfg.n_fluxos; S = cfg.tdm_slot; Ls = length(cfg.tdm_sync); Lq = Ls + N*S;
casos = {tdm_posicao(1, 2*7 + 5, N, S, Ls), ...
         [tdm_posicao(2, 4*7 + 2, N, S, Ls) tdm_posicao(2, 4*7 + 6, N, S, Ls)]};
nomes = {'(b) 1 erro na palavra 3 do fluxo A -> corrigido pelo Hamming, CRC valido', ...
         '(c) 2 erros na palavra 5 do fluxo B -> nao corrigivel, CRC de B invalido'};
cores = [0.6 0.6 0.6; 0.15 0.45 0.85; 0.9 0.45 0.1];
fig = nova_figura([1000 330]);
for c = 1:2
    y0 = 2.2 * (2 - c);                              % linha de cima = caso (b)
    for i = 1:length(tx.bits)
        pq = mod(i-1, Lq);                           % posicao dentro do quadro
        tipo = 1 + (pq >= Ls) + (pq >= Ls + S);
        rectangle('Position', [i-1 y0 1 1], 'FaceColor', cores(tipo, :), 'EdgeColor', 'none');
    end
    for q = 0:tx.n_quadros
        line([q*Lq q*Lq], [y0-0.1 y0+1.1], 'Color', 'k', 'LineWidth', 0.5);
    end
    for p = casos{c}
        rectangle('Position', [p-1 y0 1 1], 'FaceColor', [0.85 0 0], 'EdgeColor', 'k');
        text(p-0.5, y0 + 1.3, 'x', 'HorizontalAlignment', 'center', 'Color', [0.85 0 0], 'FontWeight', 'bold');
    end
    text(0, y0 - 0.4, nomes{c}, 'FontSize', 9);
end
axis([0 length(tx.bits) -0.8 3.8]); axis off;
title('T5: erros injetados (vermelho) no quadro TDM. Cinza = SYNC, azul = fluxo A, laranja = fluxo B');
salva(fig, fullfile(dir_res, 'fig_T5_erros.png'));

disp('Figuras salvas em resultados/.');
end

% ----------------------------- auxiliares -----------------------------
function fig = nova_figura(tam)
fig = figure('Position', [100 100 tam], 'Visible', 'off', 'Color', 'w');
try, theme(fig, 'light'); catch, end
end

function [f, P] = espectro(x, Fa)
x = x(:);
Nf = 2^nextpow2(length(x));
X = abs(fft(x .* hann(length(x)), Nf));
X = X(1:Nf/2);
P = 20*log10(X / max(X) + eps);
f = (0:Nf/2-1)' * Fa / Nf;
end

function salva(fig, arq)
saveas(fig, arq);
close(fig);
end
