function logCount = processJuliaSetElement(z, pow, c, escapeRadius, maxIterations)
count = 0;
magZ = abs(z);
while count <= maxIterations && magZ <= escapeRadius
    z = z^pow + c;
    count = count + 1;
    magZ = abs(z);
end
magZ = max(abs(z), escapeRadius);
logCount = tflog(count,magZ,pow);
end