function cmap = sky(m)
colors = [
    255  170    0
      0    2    0
      0    7  100
     32  107  203
    237  255  255
    255  170    0
      0    2    0
      0    7  100
     32  107  203
    237  255  255
    ]/255;

p = [-143 -57 0 64 168 257 343 400 464 568];
cmap = interp1(p, colors, linspace(0,400,m+1), 'pchip');
cmap(end,:) = [];
end