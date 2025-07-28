sampling_freq = 44100;
cutoff_freq = 1000;
taps = 89; %Number of taps of the filter
coeff_width = 16; %Width of coefficients in bits
A = int32(fir1(taps - 1, cutoff_freq / (sampling_freq / 2), 'low') * (2^(coeff_width - 1) - 1));
plot(A);
freqz(double(A) / (2^(coeff_width - 1) - 1));

for i = 1:length(A)
    hex_value = dec2hex(abs(A(i)),coeff_width / 4); %convert to hex
    if A(i) < 0 %if negative, display sign
        fprintf("-");
    end
    fprintf("%d'h%s, ", coeff_width, hex_value);

    if mod(i, 5) == 0
        fprintf("\n");
    end
end
