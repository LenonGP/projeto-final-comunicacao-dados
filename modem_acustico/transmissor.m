function [y, msg] = transmissor(msg, RB, Fp, Fa)
% transmissor.m - Hibrido MATLAB / Octave

is_octave = (exist('OCTAVE_VERSION', 'builtin') ~= 0);
if is_octave
    pkg load communications;
    pkg load signal;
end

% Converte o texto para vetor de bits (compativel com MATLAB e Octave)
msg = char(msg);
l = length(msg);
msg_dec = double(msg);
msg = reshape(de2bi([l msg_dec], 8)', 1, 8*(l+1));

% Preambulo do quadro (40 bits) e SFD (32 bits)
PRE = [ones(1,10) upsample(ones(1,15),2)];
SFD = [1 1 0 0 1 1 1 0 0 0 1 1 1 1 0 0 0 0 1 1 1 0 0 0 1 1 0 0 1 0 1 0];

% Enquadramento
msg = [PRE SFD msg PRE];

% Codificacao polar em banda base
s = [-1, 1];
y = s(msg + 1);

disp(['Tamanho do quadro: ' num2str(length(y)) ' simbolos']);

% Filtragem para formatacao de pulso (mesmo filtro para MATLAB e Octave)
r = 0.5;
RB_f = Fa / floor(Fa / RB);
num = rcosine(RB_f, Fa, 'default', r);
y = rcosflt(y, RB_f, Fa, 'filter', num)';

% Modulacao em Banda Passante (BPSK)
t = (0:length(y) - 1) / Fa;
y = y .* cos(2*pi*Fp*t);

end