% T5_integrado_software.m - Teste T5: sistema integrado com erros controlados (SOFTWARE)
% TX: fluxo -> CRC-8 -> Hamming(7,4) -> TDM ; erros injetados no quadro multiplexado ;
% RX: demux TDM -> Hamming -> CRC. Nao passa pelo canal acustico.
clear; close all; clc;
raiz = fileparts(fileparts(mfilename('fullpath')));
addpath(raiz, fullfile(raiz, 'funcoes'));
dir_res = fullfile(raiz, 'resultados'); if ~exist(dir_res, 'dir'), mkdir(dir_res); end
arq_log = fullfile(dir_res, 'T5_integrado_software.txt');
if exist(arq_log, 'file'), delete(arq_log); end
diary(arq_log);

cfg = config_modem();
fprintf('T5 - Sistema integrado com erros controlados [teste em SOFTWARE]\n\n');

tx = cadeia_tx(cfg);
n_ham = length(tx.ham{1});
Ls = length(cfg.tdm_sync); N = cfg.n_fluxos; S = cfg.tdm_slot;
fprintf('Fluxo A = "%s" | Fluxo B = "%s"\n', tx.msgs{1}, tx.msgs{2});
fprintf('Por fluxo: %d bits de dados -> %d com CRC -> %d com Hamming\n', ...
        length(tx.dados{1}), length(tx.crc{1}), n_ham);
fprintf('Quadro multiplexado: %d quadros TDM, %d bits\n\n', tx.n_quadros, length(tx.bits));

pos = @(f, k) tdm_posicao(f, k, N, S, Ls);   % k-esimo bit do fluxo f no quadro TDM

casos = {};
casos{end+1} = struct('nome', '(a) sem erro', 'pos', []);
casos{end+1} = struct('nome', '(b) 1 erro na palavra 3 de A', 'pos', pos(1, 2*7 + 5));
casos{end+1} = struct('nome', '(c) 2 erros na palavra 5 de B', 'pos', [pos(2, 4*7 + 2) pos(2, 4*7 + 6)]);

fprintf('%-40s %-6s %-8s %-9s %-10s %-9s\n', 'Caso', 'Fluxo', 'Msg', 'Iguais?', 'Corrigidos', 'CRC');
fprintf('%s\n', repmat('-', 1, 86));
esperado = {[1 1], [1 1], [1 0]};   % fluxo recuperado igual ao original?
passou = true;
for c = 1:numel(casos)
    rxbits = injeta_erros(tx.bits, casos{c}.pos);
    rx = cadeia_rx(rxbits, cfg, tx.n_quadros, n_ham);
    for f = 1:N
        igual = isequal(rx.dados{f}, tx.dados{f});
        if f == 1, nome = casos{c}.nome; else, nome = ''; end
        fprintf('%-40s %-6s %-8s %-9s %-10d %-9s\n', nome, char('A' + f - 1), ...
                ['"' rx.msg{f} '"'], ternario(igual, 'sim', 'nao'), rx.n_corr(f), ...
                ternario(rx.crc_ok(f), 'valido', 'INVALIDO'));
        passou = passou && (igual == esperado{c}(f)) && (rx.crc_ok(f) == esperado{c}(f));
    end
    if ~isempty(casos{c}.pos)
        fprintf('%-40s posicoes invertidas no quadro TDM: %s\n', '', mat2str(casos{c}.pos));
    end
end
fprintf('%s\n', repmat('-', 1, 86));
fprintf('\nResultado T5: %s\n', ternario(passou, 'PASSOU', 'FALHOU'));
fprintf('Em (c) o fluxo B nao e corrigivel (2 erros na mesma palavra) e o CRC o sinaliza,\n');
fprintf('enquanto o fluxo A continua correto: os fluxos sao independentes.\n');
diary off;
