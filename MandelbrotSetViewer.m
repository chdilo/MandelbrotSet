function figh = MandelbrotSetViewer(z0)
% 用于观察曼德博集的界面

% 创建共享数据
data = struct();
% data.DoAnimation = false;
% data.LocationList = makeLocationList();
% data.NextLocation = 2;
data.MaxIterations = 1024;
data.MaxIters = 128;
if nargin>0
    data.z0 = z0;
else
    data.z0 = 0;
end

% 创建界面
gui = createGUI();

% 设置初始视图
x0 = gpuArray.linspace( -2.5, 1.5, 1000 );
y0 = gpuArray.linspace( -2, 2, 1000 );
[x0,y0] = meshgrid(x0, y0);
z0 = complex( x0, y0 );
drawMandelbrot( gui.MandelImage, z0, data.MaxIterations );

% 如果需要，返回图形的句柄
if nargout > 0
    figh = gui.Window;
end


    function gui = createGUI()
        gui = struct();
        
        gui.Window = figure( ...
            'Name', '曼德博集浏览器', ...
            'NumberTitle', 'off', ...
            'HandleVisibility', 'off', ...
            'MenuBar', 'none', ...
            'ToolBar', 'figure',...
            'Visible', 'off', ...
            'SizeChangedFcn', @onFigureResize);
        
        % 添加一组坐标轴以显示Mandelbrot集
        gui.MandelAxes = axes(gui.Window, ...
            'Position', [0 0 1 1], ...
            'XLim', [-2.5 1.5], 'YLim', [-2 2], ...
            'XTick', [], 'YTick', [], ...
            'DataAspectRatio', [1 1 1], ...
            'ButtonDownFcn', @onMandelButtonDown );
        addlistener( gui.MandelAxes, 'YLim', 'PostSet', @mandelLimitsChanged );
        
        gui.MandelImage = imagesc(gui.MandelAxes, ...
            'CData', NaN, ...
            'XData', [-2.5 1.5], 'YData', [-2 2], ...
            'HitTest', 'off' );
        
        gui.MandelLines = line(gui.MandelAxes, ...
            'XData', zeros(1,data.MaxIters), 'YData', zeros(1,data.MaxIters), ...
            'Color', 'w', ...
            'LineWidth', 1, ...
            'Marker','.', ...
            'MarkerSize', 16, ...
            'HitTest', 'off');
        
        gui.MandelCrosshair = [
            line(gui.MandelAxes, ...
            'XData', [-2.5 1.5], 'YData', [0 0], ...
            'Color', 'w', ...
            'HitTest', 'off', ...
            'Tag', 'CrossHairH',...
            'AlignVertexCenters','on');
            line(gui.MandelAxes, ...
            'XData', [0 0], 'YData', [-2 2], ...
            'Color', 'w', ...
            'HitTest', 'off', ...
            'Tag', 'CrossHairV', ...
            'AlignVertexCenters','on');
            ];
        
        gui.CrossText = text(gui.MandelAxes,...
            real(data.z0),imag(data.z0), ...
            num2str(data.z0), ...
            'VerticalAlignment','top', ...
            'FontSize',12, ...
            'FontWeight','bold', ...
            'HitTest', 'off', ...
            'Color','k', ...
            'BackgroundColor','w',...
            'Margin',eps);
        
        
        % 从工具栏中删除一些不需要的内容
        tb = findall( gui.Window, 'Type', 'uitoolbar' );
        delete( findall( tb, 'Tag', 'Standard.FileOpen' ) );
        delete( findall( tb, 'Tag', 'Standard.NewFigure' ) );
        delete( findall( tb, 'Tag', 'Standard.EditPlot' ) );
        delete( findall( tb, 'Tag', 'Exploration.Brushing' ) );
        delete( findall( tb, 'Tag', 'Exploration.DataCursor' ) );
        delete( findall( tb, 'Tag', 'Exploration.Rotate' ) );
        delete( findall( tb, 'Tag', 'DataManager.Linking' ) );
        delete( findall( tb, 'Tag', 'Plottools.PlottoolsOn' ) );
        delete( findall( tb, 'Tag', 'Plottools.PlottoolsOff' ) );
        delete( findall( tb, 'Tag', 'Annotation.InsertLegend' ) );
        delete( findall( tb, 'Tag', 'Annotation.InsertColorbar' ) );
        % 在工具栏中添加一个切换项以隐藏数值
        
        gui.ShowCrossText = uitoggletool(tb, ...
            'CData', readIcon( 'icon_mandel.png' ), ...
            'TooltipString', '显示/隐藏数值', ...
            'State', 'on', ...
            'Separator', 'on', ...
            'ClickedCallback', @onCrossTextPressed );
        
    end % createGUI


    function cdata = readIcon( filename )
        [cdata,~,alpha] = imread( filename );
        idx = find( ~alpha );
        page = size(cdata,1)*size(cdata,2);
        cdata = im2double(cdata);
        cdata(idx) = NaN;
        cdata(idx+page) = NaN;
        cdata(idx+2*page) = NaN;
    end % readIcon


    function onMandelButtonDown( ~, ~ )
        pos = gui.MandelAxes.CurrentPoint;
        gui.Window.WindowButtonMotionFcn = @onMandelButtonMotion;
        gui.Window.WindowButtonUpFcn = @onMandelButtonUp;
        updatePosition( complex( pos(1,1), pos(1,2) ) )
    end % onMandelButtonDown


    function onMandelButtonMotion( ~, ~ )
        pos = gui.MandelAxes.CurrentPoint;
        updatePosition( complex( pos(1,1), pos(1,2) ) )
    end % onMandelButtonMotion


    function onMandelButtonUp( ~, ~ )
        pos = gui.MandelAxes.CurrentPoint;
        gui.Window.WindowButtonMotionFcn = [];
        gui.Window.WindowButtonUpFcn = [];
        updatePosition( complex( pos(1,1), pos(1,2) ) )
    end % onMandelButtonUp


    function updatePosition( z0 )
        data.z0 = z0;
        drawMandelbrotCrosshair( gui.MandelCrosshair, gui.CrossText, data.z0 );
        drawMandelLines( gui.MandelLines, data.z0, data.MaxIters );
        drawnow
    end % updatePosition


    function mandelLimitsChanged( ~, ~ )
        xlim = gui.MandelAxes.XLim;
        ylim = gui.MandelAxes.YLim;
        pixpos = getpixelposition( gui.MandelAxes );
        x0 = gpuArray.linspace( xlim(1), xlim(2), 2*max(0,round(pixpos(3))) );
        y0 = gpuArray.linspace( ylim(1), ylim(2), 2*max(0,round(pixpos(4))) );
        [x0,y0] = meshgrid(x0, y0);
        z0 = complex( x0, y0 );
        gui.MandelImage.XData = xlim;
        gui.MandelImage.YData = ylim;
        gui.MandelCrosshair(1).XData = xlim;
        gui.MandelCrosshair(2).YData = ylim;
        
        drawMandelbrotCrosshair( gui.MandelCrosshair, gui.CrossText, data.z0 );
        drawMandelbrot(gui.MandelImage, z0, data.MaxIterations);
        drawnow
    end % mandelLimitsChanged


    function onFigureResize( ~, ~ )
        pos = gui.Window.Position;
        xlim = gui.MandelAxes.XLim;
        ylim = gui.MandelAxes.YLim;
        delta_ylim = ( diff( xlim )*pos(4)/pos(3) - diff( ylim ) ) / 2;
        gui.MandelAxes.YLim = ylim + delta_ylim*[-1 1];
        
    end % onFigureResize


    function onCrossTextPressed( ~, ~ )
        state = gui.ShowCrossText.State;
        gui.CrossText.Visible = state;
        gui.MandelCrosshair(1).Visible = state;
        gui.MandelCrosshair(2).Visible = state;
    end

gui.Window.Visible = 'on';
end


function drawMandelbrot( imh, z, maxIters )
escapeRadius = 20; % 逃逸半径

pow = 2;

logCount = arrayfun( @processMandelbrotSetElement, z, pow, escapeRadius, maxIters );
logCount = gather(logCount);

n = 1000;
I = round(n*logCount);

offSet = -n*floor(min(I,[],'all')/n);
I = I + offSet;
inside = round(n*tflog(maxIters+1,escapeRadius,pow)) + offSet;
I(I == inside) = NaN;

m = max(I,[],'all');
map = repmat(sky(n),ceil(m/n),1);
cmap = [map;0 0 0];

RGB = ind2rgb(I,cmap);

imh.CData = imresize(RGB,1/2);

end % drawMandelbrot


function drawMandelbrotCrosshair( l, t, z0 )
hline = l(1);
vline = l(2);

vline.XData = real(z0)*[1 1];
hline.YData = imag(z0)*[1 1];
t.Position = [real(z0), imag(z0)];
t.String = num2str(z0);
end % drawMandelbrotCrosshair

function drawMandelLines( imh, z, maxIterations )

imh.XData(2) = real(z);
imh.YData(2) = imag(z);

for i = 3:maxIterations
    zn = complex(imh.XData(i-1), imh.YData(i-1))^2 + z;
    imh.XData(i) = real(zn);
    imh.YData(i) = imag(zn);
end

end % drawMandelLines



