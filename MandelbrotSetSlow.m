clear, clc, close all
% 曼德博集合(占内存较低,慢)
maxIterations = 1024; % 最大迭代次数
width = 1920;
height = 1080;
xlim = [-3, 1];
ylim = [-1.125, 1.125];

n = 80;
aa = 4; % 抗锯齿

x = gpuArray.linspace(xlim(1),xlim(2),aa*width);
y = gpuArray.linspace(ylim(1),ylim(2),aa*height);
y = y(1:aa*height/2);

x = reshape(x,n,[]);
y = reshape(y,n,[]);

w = reshape(1:width,n/aa,[]);
h = reshape(1:height/2,n/aa,[]);

escapeRadius = 16;
pow = 2;
level = 16384;
RGB = zeros(height/2,width,3);
for i = 1:size(y,2)
    for j = 1:size(x,2)
        [xGrid,yGrid] = meshgrid(x(:,j),y(:,i));
        z0 = complex(xGrid,-yGrid);
        
        logCount = arrayfun(@processMandelbrotSetElement, z0, pow, escapeRadius, maxIterations);
        
        I = round(level*gather(logCount));
        
        offSet = -level*floor(min(I,[],'all')/level);
        I = I + offSet;
        
        inside = round(level*tflog(maxIterations+1,escapeRadius,pow))+offSet;
        I(I == inside) = NaN;
        
        m = max(I,[],'all');
        if isnan(m)
            RGB(h(:,i),w(:,j),:) = zeros(n/aa,n/aa,3);
        else
            map = repmat(sky(level),ceil(m/level),1);
            cmap = [map;0 0 0];
            
            RGB(h(:,i),w(:,j),:) = imresize(ind2rgb(I,cmap),1/aa);
        end
    end
end
RGB = [RGB;flip(RGB)];
imshow(RGB)
imwrite(RGB,sprintf('MandelbrotSet_%ux%u.png',width,height),'BitDepth',16)

