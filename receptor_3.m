function [x, l] = receptor_3(yrx, TB, Fp, Fa)
% receptor_3.m - Copia do receptor_2.m com UMA alteracao: filtro passa-baixas
% apos a demodulacao (ver bloco 'Filtro passa-baixas'). O restante e identico.
%
% Motivo: sem o filtro, a componente em 2*Fp (= 4 kHz = Fa/2) continua no sinal
% demodulado e faz amostras vizinhas alternarem entre ~valor do simbolo e ~0.
% A decisao (e o detector early-late) passa a depender da paridade da amostra e
% do instante em que a gravacao comeca, gerando erros mesmo sem ruido.

is_octave = (exist('OCTAVE_VERSION', 'builtin') ~= 0);
if is_octave
    pkg load signal;
    pkg load communications;
end

% Sincronizacao com Costas Loop
y = yrx(:);                         % Garante vetor coluna
t = (0:length(y) - 1) / Fa;         % Instantes de amostragem
fle = 64;                           % Ordem do filtro
h = fir1(fle, 0.001);               % LPF design
mu = 0.03;                          % Tamanho do passo do algoritmo
theta = zeros(1, length(t));        % Vetor de estimativa de fase
zs = zeros(1, fle+1);
zc = zeros(1, fle+1);

for k = 1:length(t)-1
    zs = [zs(2:fle+1), 2*y(k)*sin(2*pi*Fp*t(k) + theta(k))];
    zc = [zc(2:fle+1), 2*y(k)*cos(2*pi*Fp*t(k) + theta(k))];
    lpfs = fliplr(h) * zs';
    lpfc = fliplr(h) * zc';
    theta(k+1) = theta(k) - mu * lpfs * lpfc;
end

% Demodulacao
y = y .* cos(2*pi*Fp*t + theta)';

% Filtro passa-baixas (remove a componente em 2*Fp). FIR simetrico com
% conv 'same', para nao atrasar o sinal.
h_lp = fir1(32, min(0.9, 1.5*TB/(Fa/2)));
y = conv(y, h_lp(:), 'same');

% Sincronizacao de simbolo (Early-Late)
yf = y;
st = ceil(Fa / TB);
t_idx = st;
d = 1;
err = 0.01;
si = ones(1, ceil(length(yf)/(st-1)));
for ix = 1:length(si)
    dif = abs(yf(t_idx - d)) - abs(yf(t_idx + d));
    if dif > err
        t_idx = t_idx - 1;
    elseif dif < -err
        t_idx = t_idx + 1;
    end
    si(ix) = t_idx;
    t_idx = t_idx + st;
    if t_idx > length(yf) - st + 1
        break;
    end
end
si = si(~(si > length(yf)));
y = yf(si);

% Decodificacao
x = y > 0;

% Sincronizacao do quadro via SFD
SFD = [1 1 0 0 1 1 1 0 0 0 1 1 1 1 0 0 0 0 1 1 1 0 0 0 1 1 0 0 1 0 1 0];
xc = xcorr(SFD*2 - 1, double(x)*2 - 1);
[a, b] = max(abs(xc));
if a < length(SFD)*0.9
    disp('Muitos erros para decodificar os dados');
end
if xc(b) < 0
    x = ~x;
end

% Remover cabecalho SFD
b = length(x) - b + length(SFD);
x = x(b+1:end);
l = bi2de(double(x(1:8))');
x = x(9:min(end, (l+1)*8));

end