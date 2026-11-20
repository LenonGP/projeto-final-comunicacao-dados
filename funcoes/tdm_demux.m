function [fluxos, info] = tdm_demux(bits, N, slot, n_quadros, sync)
% tdm_demux - Demultiplexacao TDM com sincronismo de quadro.
%   bits      : sequencia recebida (pode ter bits extras no inicio)
%   N         : numero de fluxos
%   slot      : bits por slot
%   n_quadros : numero de quadros esperados
%   sync      : padrao de sincronismo
% Sincronismo: para cada deslocamento possivel, conta quantos bits de sync
% coincidem em TODOS os quadros (posicoes periodicas) e escolhe o melhor.
% Isso tolera erros em alguns sync e bits de lixo antes do primeiro quadro.
% Saida:
%   fluxos{f}          bits do fluxo f (n_quadros*slot bits)
%   info.offset        bits descartados antes do primeiro quadro
%   info.sync_erros    bits de sync errados em cada quadro
%   info.faltando      bits que nao chegaram (completados com zero)
bits = double(bits(:)');
sync = sync(:)';
Ls = length(sync);
Lq = Ls + N*slot;
Ltot = n_quadros * Lq;

% --- Busca do deslocamento (sincronismo de quadro) ---
max_off = max(0, length(bits) - Ltot);
melhor = -1; offset = 0;
for off = 0:max_off
    acertos = 0;
    for q = 1:n_quadros
        i0 = off + (q-1)*Lq;
        trecho = bits(i0 + 1 : min(i0 + Ls, length(bits)));
        acertos = acertos + sum(trecho == sync(1:length(trecho)));
    end
    if acertos > melhor
        melhor = acertos; offset = off;
    end
end

% --- Recorta e completa com zeros se faltar bit ---
x = bits(offset+1 : min(end, offset + Ltot));
info.faltando = Ltot - length(x);
x = [x zeros(1, info.faltando)];

% --- Separa os slots de cada fluxo pela posicao no quadro ---
Q = reshape(x, Lq, n_quadros);                  % uma coluna por quadro
info.sync_erros = sum(Q(1:Ls, :) ~= sync(:), 1);
fluxos = cell(1, N);
for f = 1:N
    linhas = Ls + (f-1)*slot + (1:slot);
    S = Q(linhas, :);
    fluxos{f} = S(:)';
end
info.offset = offset;
end
