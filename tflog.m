function logCount = tflog(count,magZ,pow)
% 传递函数:对数
count = count - log(log(magZ))./log(abs(pow)) + 22;
if count < 0
    count = 0;
end
logCount = log(count);
end
