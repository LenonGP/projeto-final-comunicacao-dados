function cfg = config_modem()
% config_modem - Parametros unicos do projeto (enlace, fluxos, CRC, Hamming, TDM).
% Todos os scripts de teste leem daqui, para que TX e RX usem sempre os mesmos valores.

% --- Enlace (modem fornecido na disciplina) ---
cfg.RB = 100;            % taxa de bits (bps) - usada nos testes acusticos
cfg.Fp = 2000;           % portadora (Hz)
cfg.Fa = 8000;           % amostragem (Hz)
cfg.receptor = 'receptor_3';  % 'receptor_2' (original) ou 'receptor_3' (com passa-baixas)

% --- Pre-processamento do receptor (Marco 2) ---
cfg.pre_limiar = 0.3;    % inicio do sinal: primeira amostra acima de 0,3 do pico
cfg.pre_margem = 400;    % amostras mantidas antes do inicio detectado

% --- Fluxos de bits (Marco 2, Secao 4) ---
cfg.msgA = 'OLA';
cfg.msgB = 'UFS';

% --- CRC-8: G(x) = x^8 + x^2 + x + 1 (0x07, CRC-8/ATM) ---
cfg.crc_poli = [1 0 0 0 0 0 1 1 1];   % coeficientes de x^8 ate x^0

% --- TDM sincrono ---
% Cada quadro TDM = [SYNC (8 bits) | slot A (7 bits) | slot B (7 bits)] = 22 bits.
% O slot tem 7 bits = exatamente uma palavra Hamming(7,4) de cada fluxo.
cfg.tdm_sync = [0 1 1 1 1 1 1 0];     % padrao de sincronismo (flag 0x7E)
cfg.tdm_slot = 7;                     % bits por slot
cfg.n_fluxos = 2;

end
