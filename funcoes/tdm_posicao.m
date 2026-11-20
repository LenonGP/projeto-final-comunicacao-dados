function p = tdm_posicao(f, k, N, slot, sync_len)
% tdm_posicao - Indice, na sequencia multiplexada, do k-esimo bit do fluxo f.
% Usado nos testes para injetar erros em um bit/palavra especifica de um fluxo.
q = floor((k - 1) / slot);            % quadro (base 0)
j = mod(k - 1, slot);                 % posicao no slot (base 0)
Lq = sync_len + N*slot;
p = q*Lq + sync_len + (f-1)*slot + j + 1;
end
