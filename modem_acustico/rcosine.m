function [num, den] = rcosine(Fd, Fs, type_flag, r, delay, tol)
% rcosine.m - Compativel com MATLAB e GNU Octave

if (nargin < 2 || nargin > 6)
    error('Uso correto: num = rcosine(Fd, Fs, type_flag, r, delay, tol)');
end

if (nargin < 6), tol = 0.01; end
if (nargin < 5), delay = 3; end
if (nargin < 4), r = 0.5; end
if (nargin < 3), type_flag = 'fir/normal'; end

Td = 1 / Fd;
Ts = 1 / Fs;

t = -(floor(delay*Td/Ts)) : 1 : (ceil(delay*Td/Ts));
t = t .* Ts;
num = zeros(1, length(t));
den = 1;

type_flag = lower(type_flag);
if (strcmp(type_flag, 'default') || strcmp(type_flag, 'fir/normal'))
    for idx = 1:length(t)
        if (abs(r * t(idx) / Td) == 1/2)
            rSave = r;
            r = r - 1/(2^23);
            num(idx) = sinc(t(idx)/Td) * cos(pi*r*t(idx)/Td) / (1 - (2*r*t(idx)/Td)^2);
            r = rSave;
        else
            num(idx) = sinc(t(idx)/Td) * cos(pi*r*t(idx)/Td) / (1 - (2*r*t(idx)/Td)^2);
        end
    end
    num = num / sum(num);
elseif (strcmp(type_flag, 'sqrt') || strcmp(type_flag, 'fir/sqrt'))
    for idx = 1:length(t)
        if (t(idx) == 0)
            num(idx) = 1 - r + 4*(r/pi);
        elseif (abs(t(idx)) == Td/(r*4))
            num(idx) = (r/sqrt(2)) * ((1+2/pi)*sin(pi/(4*r)) + (1-2/pi)*cos(pi/(4*r)));
        else
            num(idx) = (sin(pi*(t(idx)/Td)*(1-r)) + (4*r)*(t(idx)/Td)*cos(pi*(t(idx)/Td)*(1+r)));
            num(idx) = num(idx) / (pi * (t(idx)/Td) * (1 - (4*r*(t(idx)/Td))^2));
        end
    end
    num = num / sum(num);
end

end