% rx_enlace.m - Receptor do Enlace Basico (Compativel com MATLAB e Octave)
clear; close all; clc;

is_octave = (exist('OCTAVE_VERSION', 'builtin') ~= 0);
if is_octave
    pkg load signal;
    pkg load communications;
end

% --- Parametros do Enlace (Iguais ao TX) ---
RB = 100;       % Taxa de bits (bps)
Fp = 2000;      % Frequencia da portadora (Hz)
Fa = 8000;      % Frequencia de amostragem (Hz)

% Sequencia conhecida enviada pelo TX
msg_esperada = 'OLA';
bits_tx = reshape(de2bi(double(msg_esperada), 8)', 1, 8 * length(msg_esperada));

% --- Controle de Captura ---
% on = 1 -> Captura do microfone em tempo real (usa record no Octave e audiorecorder no MATLAB)
% on = 0 -> Le o arquivo .wav ja gravado
on = 1;
%filename = 'sinal_tx_gerado.wav'; % pode testar sinal_rx2.wav e sinal_rx3.wav
filename = 'sinal/sinal_rx.wav';

if ~exist('sinal', 'dir'), mkdir('sinal'); end

if on == 1
    NS = 0;
    NS_min = 0.1;
    t_captura = 4;
    disp('Aguardando sinal acustico no microfone...');
    if ~is_octave
        recObj = audiorecorder(Fa, 16, 1);
    end
    while NS < NS_min
        if is_octave
            y = record(t_captura, Fa);
        else
            recordblocking(recObj, t_captura);
            y = getaudiodata(recObj, 'double');
        end
        if ~isempty(y)
            NS = max(abs(y));
        end
    end
    disp(['Sinal detectado! Pico de amplitude: ' num2str(NS)]);
    audiowrite(filename, y, Fa);
else
    [y, fs] = audioread(filename);
    disp(['Lendo captura acustica do arquivo: ' filename]);
end

% --- Pre-processamento (vale para on = 0 e on = 1) ---
y = y(:,1);                            % so o primeiro canal
y = y / max(abs(y));                   % normaliza a amplitude (Costas loop depende de A^2)
i0 = find(abs(y) > 0.3, 1);            % inicio do quadro (ajuste o limiar se precisar)
y = y(max(1, i0 - 400):end);           % descarta o silencio/ruido inicial
 

% --- Demodulacao e Recuperacao dos Bits ---
[m, l_rx] = receptor_2(y, RB, Fp, Fa);
bits_rx = double(m(:)');

% --- Conversao dos bits para texto ---
n_bytes = floor(length(bits_rx) / 8);
if n_bytes > 0
    x = bi2de(reshape(bits_rx(1:n_bytes*8), 8, n_bytes)')';
    msg_rx = char(x);
else
    msg_rx = '';
end

% --- Comparacao Bit a Bit ---
n_comp = min(length(bits_tx), length(bits_rx));
erros = sum(xor(bits_tx(1:n_comp), bits_rx(1:n_comp))) + (length(bits_tx) - n_comp);
ber = (erros / length(bits_tx)) * 100;

if on == 1, modo = 'Captura acustica'; else, modo = 'Simulacao (arquivo)'; end
fprintf('\n================ RECEPTOR DO ENLACE ================\n');
fprintf('Tamanho decodificado: %d bytes\n', l_rx);
fprintf('Mensagem transmitida: "%s"\n', msg_esperada);
fprintf('Mensagem recuperada:  "%s"\n', msg_rx);
fprintf('Bits Transmitidos (%d bits):\n', length(bits_tx));
disp(bits_tx);
fprintf('Bits Recuperados  (%d bits):\n', length(bits_rx));
disp(bits_rx);
fprintf('Quantidade de erros:  %d de %d bits (BER = %.2f%%)\n', erros, length(bits_tx), ber);
fprintf('====================================================\n');

% --- Graficos do Receptor ---
figure(2);
subplot(2,1,1);
t_rx = (0:length(y) - 1) / Fa;
plot(t_rx, y, 'r'); grid on;
title([modo ' - ' strrep(filename, '_', '\_') ' (normalizado)']);
xlabel('Tempo (s)'); ylabel('Amplitude');

subplot(2,1,2);
stem(1:n_comp, bits_tx(1:n_comp), 'b', 'filled'); hold on;
stem(1:n_comp, bits_rx(1:n_comp), 'r--', 'LineWidth', 1.5);
grid on; ylim([-0.2 1.3]);
title([modo ': comparacao de bits (Erros = ' num2str(erros) ')']);
xlabel('Indice do Bit'); ylabel('Nivel Logico');
legend('Bits TX', 'Bits RX', 'Location', 'northeast');