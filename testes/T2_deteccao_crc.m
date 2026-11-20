% T2_deteccao_crc.m - Teste T2: deteccao de erros com CRC-8 (SOFTWARE)
% Erros introduzidos de forma controlada; nao passa pelo canal acustico.
clear; close all; clc;
raiz = fileparts(fileparts(mfilename('fullpath')));
addpath(raiz, fullfile(raiz, 'funcoes'));
dir_res = fullfile(raiz, 'resultados'); if ~exist(dir_res, 'dir'), mkdir(dir_res); end
arq_log = fullfile(dir_res, 'T2_deteccao_crc.txt');
if exist(arq_log, 'file'), delete(arq_log); end
diary(arq_log);

cfg = config_modem();
fprintf('T2 - Deteccao de erros com CRC-8 [teste em SOFTWARE]\n');
fprintf('Polinomio gerador: G(x) = x^8 + x^2 + x + 1 (0x07)\n\n');

dados = texto2bits(cfg.msgA);
cw = crc8_anexa(dados, cfg.crc_poli);
n = length(cw);
fprintf('Fluxo A = "%s" (%d bits)\n', cfg.msgA, length(dados));
fprintf('Dados : %s\n', sprintf('%d', dados));
fprintf('CRC   : %s\n', sprintf('%d', cw(end-7:end)));
fprintf('Total : %d bits\n\n', n);

% (a) sem erro
ok_a = crc8_verifica(cw, cfg.crc_poli);
fprintf('(a) Sem erro: CRC %s\n\n', ternario(ok_a, 'VALIDO', 'INVALIDO'));

% Exemplo explicito de um erro
p_ex = 10;
[ok_ex, ~, resto] = crc8_verifica(injeta_erros(cw, p_ex), cfg.crc_poli);
fprintf('Exemplo: bit %d invertido -> resto = %s -> CRC %s\n\n', p_ex, ...
        sprintf('%d', resto), ternario(ok_ex, 'VALIDO', 'INVALIDO'));

% (b) 1 bit em cada posicao
det_b = 0;
for p = 1:n
    det_b = det_b + ~crc8_verifica(injeta_erros(cw, p), cfg.crc_poli);
end

% (c) 2 bits, todas as combinacoes de posicoes
pares = nchoosek(1:n, 2);
det_c = 0;
for k = 1:size(pares, 1)
    det_c = det_c + ~crc8_verifica(injeta_erros(cw, pares(k, :)), cfg.crc_poli);
end

% (d) rajadas de 2 a 8 bits: primeiro e ultimo bit invertidos, bits internos
%     em todas as combinacoes possiveis, em todas as posicoes iniciais
tot_d = zeros(1, 8); det_d = zeros(1, 8);
for L = 2:8
    for ini = 1:(n - L + 1)
        for padrao = 0:(2^(L-2) - 1)
            interno = mod(floor(padrao ./ 2.^(0:L-3)), 2);   % bits internos da rajada
            e = [1 interno 1];
            pos = ini - 1 + find(e);
            tot_d(L) = tot_d(L) + 1;
            det_d(L) = det_d(L) + ~crc8_verifica(injeta_erros(cw, pos), cfg.crc_poli);
        end
    end
end

fprintf('%-38s %10s %10s %10s\n', 'Caso', 'Injetados', 'Detectados', 'Nao det.');
fprintf('%s\n', repmat('-', 1, 72));
fprintf('%-38s %10d %10d %10d\n', '(a) sem erro (falso positivo?)', 1, ~ok_a, 0);
fprintf('%-38s %10d %10d %10d\n', '(b) 1 bit, cada posicao', n, det_b, n - det_b);
fprintf('%-38s %10d %10d %10d\n', '(c) 2 bits, todos os pares', size(pares, 1), det_c, size(pares, 1) - det_c);
for L = 2:8
    fprintf('%-38s %10d %10d %10d\n', sprintf('(d) rajada de %d bits', L), tot_d(L), det_d(L), tot_d(L) - det_d(L));
end
fprintf('%s\n', repmat('-', 1, 72));

passou = ok_a && det_b == n && det_c == size(pares, 1) && all(det_d(2:8) == tot_d(2:8));
fprintf('\nResultado T2: %s\n', ternario(passou, 'PASSOU (nenhum erro injetado passou como valido)', 'FALHOU'));
diary off;
