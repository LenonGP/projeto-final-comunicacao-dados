% T3_correcao_hamming.m - Teste T3: correcao de erros com Hamming(7,4) (SOFTWARE)
% Erros introduzidos de forma controlada; nao passa pelo canal acustico.
clear; close all; clc;
raiz = fileparts(fileparts(mfilename('fullpath')));
addpath(raiz, fullfile(raiz, 'funcoes'));
dir_res = fullfile(raiz, 'resultados'); if ~exist(dir_res, 'dir'), mkdir(dir_res); end
arq_log = fullfile(dir_res, 'T3_correcao_hamming.txt');
if exist(arq_log, 'file'), delete(arq_log); end
diary(arq_log);

cfg = config_modem();
rng(2026);   % semente fixa para os sorteios do item (c)
fprintf('T3 - Correcao de erros com Hamming(7,4) [teste em SOFTWARE]\n');
fprintf('Palavra: [p1 p2 d1 p3 d2 d3 d4]; corrige 1 bit por palavra de 7 bits.\n\n');

% Exemplo explicito
d_ex = [1 0 1 1];
c_ex = hamming74_codifica(d_ex);
r_ex = injeta_erros(c_ex, 5);
[d_rec, ~, p_rec] = hamming74_decodifica(r_ex);
fprintf('Exemplo: dados %s -> palavra %s\n', sprintf('%d', d_ex), sprintf('%d', c_ex));
fprintf('         bit 5 invertido -> %s -> sindrome aponta posicao %d -> dados %s\n\n', ...
        sprintf('%d', r_ex), p_rec, sprintf('%d', d_rec));

% (a) as 16 palavras, 1 erro em cada uma das 7 posicoes
tot_a = 0; ok_a = 0;
for v = 0:15
    d = bitget(v, 1:4);
    c = hamming74_codifica(d);
    for p = 1:7
        tot_a = tot_a + 1;
        ok_a = ok_a + isequal(hamming74_decodifica(injeta_erros(c, p)), d);
    end
end

% (b) as 16 palavras, 2 erros na mesma palavra (todos os 21 pares)
pares = nchoosek(1:7, 2);
tot_b = 0; ok_b = 0;
for v = 0:15
    d = bitget(v, 1:4);
    c = hamming74_codifica(d);
    for k = 1:size(pares, 1)
        tot_b = tot_b + 1;
        ok_b = ok_b + isequal(hamming74_decodifica(injeta_erros(c, pares(k, :))), d);
    end
end

% (b2) 2 erros na mesma palavra do fluxo A completo (CRC + Hamming):
%      o CRC deve sinalizar o erro residual
dados = texto2bits(cfg.msgA);
crcA = crc8_anexa(dados, cfg.crc_poli);
hamA = hamming74_codifica(crcA);
n_pal = length(hamA) / 7;
tot_b2 = 0; crc_inv_b2 = 0;
for w = 1:n_pal
    for k = 1:size(pares, 1)
        r = injeta_erros(hamA, (w-1)*7 + pares(k, :));
        tot_b2 = tot_b2 + 1;
        crc_inv_b2 = crc_inv_b2 + ~crc8_verifica(hamming74_decodifica(r), cfg.crc_poli);
    end
end

% (c) fluxo A completo com 1 erro (posicao sorteada) em CADA palavra
pos_c = zeros(1, n_pal);
for w = 1:n_pal
    pos_c(w) = (w-1)*7 + randi(7);
end
rA = injeta_erros(hamA, pos_c);
[crc_rec, n_corr_c] = hamming74_decodifica(rA);
[ok_crc_c, dados_rec] = crc8_verifica(crc_rec, cfg.crc_poli);

fprintf('(c) Fluxo A = "%s": %d palavras de 7 bits (%d bits)\n', cfg.msgA, n_pal, length(hamA));
fprintf('    Posicoes invertidas: %s\n', mat2str(pos_c));
fprintf('    Palavras corrigidas: %d | CRC: %s | Mensagem: "%s"\n\n', n_corr_c, ...
        ternario(ok_crc_c, 'VALIDO', 'INVALIDO'), bits2texto(dados_rec));

fprintf('%-46s %9s %11s %11s\n', 'Caso', 'Casos', 'Recuperado', 'Errado');
fprintf('%s\n', repmat('-', 1, 80));
fprintf('%-46s %9d %11d %11d\n', '(a) 1 erro, 16 palavras x 7 posicoes', tot_a, ok_a, tot_a - ok_a);
fprintf('%-46s %9d %11d %11d\n', '(b) 2 erros, 16 palavras x 21 pares', tot_b, ok_b, tot_b - ok_b);
fprintf('%-46s %9d %11d %11d\n', '(c) fluxo A, 1 erro em cada palavra', 1, isequal(dados_rec, dados), ~isequal(dados_rec, dados));
fprintf('%s\n', repmat('-', 1, 80));
fprintf('(b2) Fluxo A, 2 erros na mesma palavra: CRC sinalizou %d de %d casos\n', crc_inv_b2, tot_b2);

passou = ok_a == tot_a && ok_b == 0 && isequal(dados_rec, dados) && crc_inv_b2 == tot_b2;
fprintf('\nResultado T3: %s\n', ternario(passou, 'PASSOU', 'FALHOU'));
fprintf('Limite do codigo: distancia minima 3 -> corrige 1 erro por palavra de 7 bits;\n');
fprintf('com 2 erros na mesma palavra a decodificacao erra, e o CRC-8 detecta o residuo.\n');
diary off;
