function cmap = grayscale(m)
% 灰阶渐变
colors = [
    255  255  255
    000  000  000
    255  255  255
    000  000  000
    255  255  255
    ]/255;

p = [-200 0 200 400 600];
cmap = interp1(p, colors, linspace(0,400,m+1), 'pchip');
cmap(end,:) = [];
end