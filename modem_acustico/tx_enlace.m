% tx_enlace.m - Transmissor do Enlace Basico (Compativel com MATLAB e Octave)
clear; close all; clc;

is_octave = (exist('OCTAVE_VERSION', 'builtin') ~= 0);
if is_octave
    pkg load signal;
    pkg load communications;
end

% --- Parametros do Enlace ---
msg = 'OLA';    % Aspas simples funcionam como char tanto no MATLAB quanto no Octave
RB = 400;       % Taxa de bits (bps)
Fp = 2000;      % Frequencia da portadora (Hz)
Fa = 8000;      % Frequencia de amostragem (Hz)

% --- Extrai os bits de dados puros para comparacao ---
l_tx = length(msg);
bits_dados_tx = reshape(de2bi(double(msg), 8)', 1, 8 * l_tx);

% --- Executa o transmissor do modem ---
[ytx, quadro_completo] = transmissor(msg, RB, Fp, Fa);

fprintf('================ TRANSMISSOR DO ENLACE ================\n');
fprintf('Ambiente detectado:   %s\n', ifelse_str(is_octave, 'GNU Octave', 'MATLAB'));
fprintf('Mensagem transmitida: "%s" (%d bytes)\n', msg, l_tx);
fprintf('Taxa de bits (RB):    %d bps\n', RB);
fprintf('Portadora (Fp):       %d Hz | Amostragem (Fa): %d Hz\n', Fp, Fa);
fprintf('Tamanho do quadro:    %d simbolos\n', length(quadro_completo));
fprintf('Amostras de audio:    %d amostras (Duracao: %.2f s)\n', length(ytx), length(ytx)/Fa);
fprintf('Sequencia de bits TX (%d bits):\n', length(bits_dados_tx));
disp(bits_dados_tx);
fprintf('=======================================================\n');

% Salva o audio modulado
audiowrite('sinal_tx_gerado.wav', ytx / max(abs(ytx)), Fa);

% --- Transmissao Acustica pelo Alto-Falante ---
disp('Transmitindo sinal acustico pelo alto-falante...');
soundsc(ytx, Fa);

% --- Grafico do Sinal Transmitido ---
t = (0:length(ytx) - 1) / Fa;
figure(1);
plot(t, ytx, 'b'); grid on;
title(['Sinal BPSK Transmitido no Enlace (RB = ' num2str(RB) ' bps, Fp = ' num2str(Fp) ' Hz)']);
xlabel('Tempo (s)'); ylabel('Amplitude');

function out = ifelse_str(cond, s_true, s_false)
    if cond, out = s_true; else, out = s_false; end
end