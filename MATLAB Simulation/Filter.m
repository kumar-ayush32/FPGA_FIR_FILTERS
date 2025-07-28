fs=600;
n=100;
b=fir1(n,120/600*2,'LOW');
fvtool(b);
figure;
t1 = 0:1/fs:2*pi;
y1 = sin(50*2*pi*t1) + sin(100*2*pi*t1) + sin(150*2*pi*t1) + sin(180*2*pi*t1);
Y1 = fft(y1);
L1 = length(y1);
f1 = (0:L1-1)*(fs/L1);
amplitude1 = abs(Y1);
plot(f1, amplitude1);
grid on;
title("Fourier Transform(0 to 2*pi)");
xlabel('Frequency (Hz)');
ylabel('Amplitude');

figure;
t2 = -pi:1/fs:pi;
y2 = sin(50*2*pi*t2) + sin(100*2*pi*t2) + sin(150*2*pi*t2) + sin(180*2*pi*t2);
Y2 = fft(y2);
L2 = length(y2);
f2 = [(0:L2/2-1)*(fs/L2) , (-L2/2:-1)*(fs/L2)];
amplitude2 = abs(Y2);
plot(f2, amplitude2);
grid on;
title("Fourier Transform(-pi to pi)");
xlabel('Frequency (Hz)');
ylabel('Amplitude');

filter1 = zeros(1, L1);
for i = 1:L1
    temp = 0;
    for k = 0:n
        temp = temp + b(k+1) * exp(-1j * 2 * pi * f1(i) * k / fs );
    end
    filter1(i) = temp;
end
figure;
subplot(2, 1, 1);
plot(f1, abs(filter1));
title("Filter used");
xlabel('Frequency (Hz)');
ylabel('Amplitude');
subplot(2, 1, 2);
plot(f1, amplitude1 .* abs(filter1));
title("Filter Higher frequency greater than 100");
xlabel('Frequency (Hz)');
ylabel('Amplitude');

filter2 = zeros(1, L1);
for i = 1:L2
    temp = 0;
    for k = 0:n
        temp = temp + b(k+1) * exp(-1j * 2 * pi * f2(i) * k / fs );
    end
    filter2(i) = temp;
end
figure;
subplot(2, 1, 1);
plot(f2, abs(filter2));
title("Filter used");
xlabel('Frequency (Hz)');
ylabel('Amplitude');
subplot(2, 1, 2);
plot(f2, amplitude1 .* abs(filter2));
title("After applying the filter");
xlabel('Frequency (Hz)');
ylabel('Amplitude');
