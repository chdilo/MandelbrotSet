function logCount = processMandelbrotSetElement(z0, pow, escapeRadius, maxIterations)
z = z0;
count = 0;
magZ = abs(z);
while count <= maxIterations && magZ <= escapeRadius
    z = z^pow + z0;
    count = count + 1;
    magZ = abs(z);
end
magZ = max(abs(z), escapeRadius);
logCount = tflog(count,magZ,pow);
end