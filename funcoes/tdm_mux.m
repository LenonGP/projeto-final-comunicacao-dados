function [bits, n_quadros] = tdm_mux(fluxos, slot, sync)
% tdm_mux - Multiplexacao por divisao de tempo (TDM sincrono).
%   fluxos : cell com N vetores de bits (um por fluxo)
%   slot   : bits de cada fluxo por quadro
%   sync   : padrao de sincronismo no inicio de cada quadro
% Quadro q = [sync | fluxo1(slot q) | fluxo2(slot q) | ... | fluxoN(slot q)]
% Fluxos mais curtos sao completados com zeros ate n_quadros*slot bits.
N = numel(fluxos);
L = max(cellfun(@numel, fluxos));
n_quadros = ceil(L / slot);
M = zeros(N, n_quadros * slot);
for f = 1:N
    x = double(fluxos{f}(:)');
    M(f, 1:length(x)) = x;
end
bits = [];
for q = 1:n_quadros
    idx = (q-1)*slot + (1:slot);
    quadro = sync(:)';
    for f = 1:N
        quadro = [quadro M(f, idx)]; %#ok<AGROW>
    end
    bits = [bits quadro]; %#ok<AGROW>
end
end
