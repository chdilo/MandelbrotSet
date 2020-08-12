function logCount = tflog(count,magZ,pow)

count = count - log(log(magZ))./log(abs(pow)) + 22;
if count < 0
    count = 0;
end
logCount = log(count);

