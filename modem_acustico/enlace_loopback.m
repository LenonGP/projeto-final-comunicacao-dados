% enlace_loopback.m - TX e RX na mesma sessao (alto-falante -> microfone)
% Deixe este arquivo na pasta com: transmissor.m, receptor_2.m, rcosine.m, rcosflt.m
% Toca o sinal do transmissor no alto-falante, grava no microfone, decodifica
% com o receptor_2 e compara com os bits enviados. Repete n_rodadas vezes.
clear; close all; clc;

is_octave = (exist('OCTAVE_VERSION', 'builtin') ~= 0);
if is_octave
    pkg load signal;
    pkg load communications;
end

% --- Parametros do Enlace (usados no TX e no RX) ---
msg = 'OLA';
RB  = 100;          % Taxa de bits (bps)
Fp  = 2000;         % Frequencia da portadora (Hz)
Fa  = 8000;         % Frequencia de amostragem (Hz)

% --- Parametros do teste ---
n_rodadas = 3;      % quantas vezes repetir
t_pre  = 1;         % segundos de silencio gravado antes do sinal
t_pos  = 1;         % segundos de cauda gravada depois do sinal
NS_min = 0.02;      % se o pico gravado ficar abaixo disso, avisa (volume/distancia)

% --- Bits de dados puros, para comparacao ---
bits_tx = reshape(de2bi(double(msg), 8)', 1, 8 * length(msg));

% --- Transmissor: gera o sinal (vetor de amostras) ---
[ytx, quadro] = transmissor(msg, RB, Fp, Fa);
ytx = ytx(:) / max(abs(ytx));       % coluna, normalizada para o volume maximo
dur = length(ytx) / Fa;

fprintf('Mensagem: "%s" | RB = %d bps | Fp = %d Hz | Fa = %d Hz\n', msg, RB, Fp, Fa);
fprintf('Quadro: %d simbolos | Sinal: %.2f s\n', length(quadro), dur);
fprintf('Microfone perto do alto-falante, volume alto, sala em silencio.\n\n');

if ~exist('sinal', 'dir'), mkdir('sinal'); end

erros_r = nan(1, n_rodadas);
for r = 1:n_rodadas
    rec = audiorecorder(Fa, 16, 1);
    ply = audioplayer(ytx, Fa);

    fprintf('Rodada %d/%d: gravando e transmitindo...\n', r, n_rodadas);
    record(rec);                     % comeca a gravar (nao bloqueia)
    pause(t_pre);
    play(ply);                       % toca o sinal no alto-falante
    pause(dur + t_pos);
    stop(rec);
    y = getaudiodata(rec, 'double');
    y = y(:,1);

    pico = max(abs(y));
    if pico < NS_min
        fprintf('  AVISO: pico gravado = %.3f (baixo). Aumente o volume ou aproxime o microfone.\n', pico);
    end
    arq = sprintf('sinal/captura_rb%d_r%d.wav', RB, r);
    audiowrite(arq, y, Fa);          % guarda como evidencia

    % --- Pre processamento ---
    y = y / max(abs(y));                   
    i0 = find(abs(y) > 0.3, 1);            
    y = y(max(1, i0 - 400):end);           

    % --- Receptor ---
    try
        [m, l_rx] = receptor_2(y, RB, Fp, Fa);
        bits_rx = double(m(:)');
    catch
        l_rx = 0; bits_rx = [];
    end

    n_bytes = floor(length(bits_rx) / 8);
    if n_bytes > 0
        msg_rx = char(bi2de(reshape(bits_rx(1:n_bytes*8), 8, n_bytes)')');
        msg_rx(msg_rx < 32 | msg_rx > 126) = '?';
    else
        msg_rx = '';
    end

    % --- Comparacao bit a bit (bits que faltam contam como erro) ---
    n_comp = min(length(bits_tx), length(bits_rx));
    erros = sum(xor(bits_tx(1:n_comp), bits_rx(1:n_comp))) + (length(bits_tx) - n_comp);
    erros_r(r) = erros;
    ber = 100 * erros / length(bits_tx);

    fprintf('  Pico = %.3f | l_rx = %d | msg = "%s" | erros = %d de %d (BER = %.1f%%)\n', ...
            pico, l_rx, msg_rx, erros, length(bits_tx), ber);
    fprintf('  Arquivo salvo: %s\n\n', arq);

    y_ult = y; bits_rx_ult = bits_rx; n_comp_ult = n_comp;
    pause(1);
end

% --- Resumo ---
fprintf('================ RESUMO ================\n');
fprintf('Rodadas: %d | Erros por rodada: %s\n', n_rodadas, mat2str(erros_r));
fprintf('BER medio: %.2f%%\n', 100 * mean(erros_r) / length(bits_tx));
fprintf('========================================\n');

% --- Graficos da ultima rodada ---
figure(1);
subplot(2,1,1);
plot((0:length(y_ult)-1)/Fa, y_ult, 'r'); grid on;
title(sprintf('Captura acustica (RB = %d bps) - rodada %d', RB, n_rodadas));
xlabel('Tempo (s)'); ylabel('Amplitude');

subplot(2,1,2);
if n_comp_ult > 0
    stem(1:n_comp_ult, bits_tx(1:n_comp_ult), 'b', 'filled'); hold on;
    stem(1:n_comp_ult, bits_rx_ult(1:n_comp_ult), 'r--', 'LineWidth', 1.5);
    legend('Bits TX', 'Bits RX', 'Location', 'northeast');
end
grid on; ylim([-0.2 1.3]);
title(sprintf('Captura acustica: comparacao de bits (Erros = %d)', erros_r(n_rodadas)));
xlabel('Indice do Bit'); ylabel('Nivel Logico');