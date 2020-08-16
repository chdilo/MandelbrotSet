function figh = JuliaSetViewer(z0)
% 用于观察朱利亚集的界面

% 创建共享数据
data = struct();
data.DoAnimation = false;
data.LocationList = makeLocationList();
data.NextLocation = 2;
data.MaxIterations = 1000;
if nargin>0
    data.z0 = z0;
else
    data.z0 = data.LocationList(1);
end
x = gpuArray.linspace( -2, 2, 1000 );
y = gpuArray.linspace( -2, 2, 1000 );
[x,y] = meshgrid(x, y);
data.z = complex(x, y);
clear x y

% 创建界面
gui = createGUI();

% 设置初始视图
x0 = gpuArray.linspace( -2, 0.5, 1000 );
y0 = gpuArray.linspace( -1.25, 1.25, 1000 );
[x0,y0] = meshgrid(x0, y0);
z0 = complex( x0, y0 );
drawMandelbrot( gui.MandelImage, z0, data.MaxIterations );
onLimitsChanged();

% 设置路径动画
if data.DoAnimation
    doAnimation();
end

% 如果需要，返回图形的句柄
if nargout > 0
    figh = gui.Window;
end


    function gui = createGUI()
        gui = struct();
        
        gui.Window = figure( ...
            'Name', '朱利亚集浏览器', ...
            'NumberTitle', 'off', ...
            'HandleVisibility', 'off', ...
            'MenuBar', 'none', ...
            'ToolBar', 'figure',...
            'Visible', 'off', ...
            'SizeChangedFcn', @onFigureResize);
        
        gui.JuliaAxes = axes(gui.Window, ...
            'Position', [0.5 0 0.5 1], ...
            'XLim', [-2 2], 'YLim', [-2 2], ...
            'XTick', [], 'YTick', [], ...
            'DataAspectRatio', [1 1 1] ,...
            'Colormap',[repmat(sky(1000),100,1);0 0 0], ...
            'CLim',[1 10000]);
        addlistener( gui.JuliaAxes, 'YLim', 'PostSet', @onLimitsChanged );
        
        % 同时添加一组坐标轴以显示Mandelbrot集
        gui.MandelAxes = axes(gui.Window, ...
            'Position', [0 0 0.5 1], ...
            'XLim', [-2 0.5], 'YLim', [-1.25 1.25], ...
            'XTick', [], 'YTick', [], ...
            'DataAspectRatio', [1 1 1] ,...
            'Colormap',[repmat(sky(1000),100,1);0 0 0], ...
            'CLim',[1 10000], ...
            'ButtonDownFcn', @onMandelButtonDown );
        addlistener( gui.MandelAxes, 'YLim', 'PostSet', @mandelLimitsChanged );
        
        gui.JuliaImage = imagesc(gui.JuliaAxes, ...
            'CData', NaN, ...
            'XData', [-2 2], 'YData', [-2 2] );
        
        gui.MandelImage = imagesc(gui.MandelAxes, ...
            'CData', NaN, ...
            'XData', [-2 0.5], 'YData', [-1.25 1.25], ...
            'HitTest', 'off' );
        
        gui.MandelCrosshair = [
            line(gui.MandelAxes, ...
            'XData', [-2 0.5], 'YData', [0 0], ...
            'Color', 'w', ...
            'HitTest', 'off', ...
            'Tag', 'CrossHairH' );
            line(gui.MandelAxes, ...
            'XData', [0 0], 'YData', [-2 2], ...
            'Color', 'w', ...
            'HitTest', 'off', ...
            'Tag', 'CrossHairV' );
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
        % 在工具栏中添加一个切换项以隐藏mandelbrot视图
        gui.ShowMandelToggle = uitoggletool(tb, ...
            'CData', readIcon( 'icon_mandel.png' ), ...
            'TooltipString', '显示/隐藏Mandelbrot视图', ...
            'State', 'on', ...
            'Separator', 'on', ...
            'ClickedCallback', @onMandelTogglePressed );
        
        gui.AnimToggle = uitoggletool(tb, ...
            'CData', readIcon( 'icon_play.png' ), ...
            'TooltipString', '播放动画', ...
            'State', 'off', ...
            'ClickedCallback', @onAnimTogglePressed );
        
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
        drawJulia( gui.JuliaImage, data.z, data.z0, data.DoAnimation, data.MaxIterations );
        
        drawnow
    end % updatePosition


    function onLimitsChanged( ~, ~ )
        % 为了计算出要绘制的内容和分辨率，需要坐标轴范围和像素数
        xlim = gui.JuliaAxes.XLim;
        ylim = gui.JuliaAxes.YLim;
        pixpos = getpixelposition( gui.JuliaAxes );
        x = gpuArray.linspace( xlim(1), xlim(2), max(0,round(pixpos(3))) );
        y = gpuArray.linspace( ylim(1), ylim(2), max(0,round(pixpos(4))) );
        [x,y] = meshgrid(x, y);
        data.z = complex( x, y );
        gui.JuliaImage.XData = xlim;
        gui.JuliaImage.YData = ylim;
        
        updatePosition( data.z0 );
    end % onLimitsChanged


    function mandelLimitsChanged( ~, ~ )
        xlim = gui.MandelAxes.XLim;
        ylim = gui.MandelAxes.YLim;
        pixpos = getpixelposition( gui.MandelAxes );
        x0 = gpuArray.linspace( xlim(1), xlim(2), max(0,round(pixpos(3))) );
        y0 = gpuArray.linspace( ylim(1), ylim(2), max(0,round(pixpos(4))) );
        [x0,y0] = meshgrid(x0, y0);
        z0 = complex( x0, y0 );
        gui.MandelImage.XData = xlim;
        gui.MandelImage.YData = ylim;
        
        drawMandelbrotCrosshair( gui.MandelCrosshair, gui.CrossText, data.z0 );
        drawMandelbrot(gui.MandelImage, z0, data.MaxIterations);
        drawnow
    end % onLimitsChanged


    function onFigureResize( ~, ~ )
        pos = gui.Window.Position;
        xlim = gui.MandelAxes.XLim;
        ylim = gui.MandelAxes.YLim;
        delta_ylim = ( 2*diff( xlim )*pos(4)/pos(3) - diff( ylim ) ) / 2;
        gui.MandelAxes.YLim = ylim + delta_ylim*[-1 1];
        
        xlim = gui.JuliaAxes.XLim;
        ylim = gui.JuliaAxes.YLim;
        if strcmpi( gui.ShowMandelToggle.State, 'on' )
            delta_ylim = ( 2*diff( xlim )*pos(4)/pos(3) - diff( ylim ) ) / 2;
        else
            delta_ylim = ( diff( xlim )*pos(4)/pos(3) - diff( ylim ) ) / 2;
        end
        gui.JuliaAxes.YLim = ylim + delta_ylim*[-1 1];
        
    end % onFigureResize


    function onMandelTogglePressed( ~, ~ )
        % 打开和关闭Mandelbrot视图
        state = gui.ShowMandelToggle.State;
        gui.MandelAxes.Visible = state;
        gui.MandelAxes.HitTest = state;
        gui.MandelImage.Visible = state;
        gui.MandelCrosshair(1).Visible = state;
        gui.MandelCrosshair(2).Visible = state;
        if strcmpi( gui.ShowCrossText.State, 'on' )
            gui.CrossText.Visible = state;
        end
        pos = gui.Window.Position;
        if strcmpi( gui.ShowMandelToggle.State, 'on' )
            gui.JuliaAxes.Position = [0.5 0 0.5 1];
            xlim = gui.JuliaAxes.XLim;
            ylim = gui.JuliaAxes.YLim;
            delta_ylim = ( 2*diff( xlim )*pos(4)/pos(3) - diff( ylim ) ) / 2;
            gui.JuliaAxes.YLim = ylim + delta_ylim*[-1 1];
        else
            gui.JuliaAxes.Position = [0 0 1 1];
            xlim = gui.JuliaAxes.XLim;
            ylim = gui.JuliaAxes.YLim;
            delta_ylim = ( diff( xlim )*pos(4)/pos(3) - diff( ylim ) ) / 2;
            gui.JuliaAxes.YLim = ylim + delta_ylim*[-1 1];
        end
    end


    function onCrossTextPressed( ~, ~ )
        state = gui.ShowCrossText.State;
        if strcmpi( gui.ShowMandelToggle.State, 'on' )
            gui.CrossText.Visible = state;
        end
    end


    function onAnimTogglePressed( ~, ~ )
        data.DoAnimation = strcmpi( gui.AnimToggle.State, 'on' );
        if data.DoAnimation
            doAnimation();
        end
    end


    function doAnimation()
        while data.DoAnimation
            if ~ishandle( gui.Window )
                return;
            end
            updatePosition( data.LocationList(data.NextLocation) );
            data.NextLocation = mod( data.NextLocation, numel( data.LocationList ) ) + 1;
        end
        % 在关闭动画时重画
        updatePosition( data.LocationList(data.NextLocation) );
    end  % doAnimation


gui.Window.Visible = 'on';
end


function drawMandelbrot( imh, z, maxIters )
escapeRadius = 20; % 逃逸半径
z0 = z;
pow = 2;
logCount = arrayfun( @processMandelbrotSetElement, z0, pow, escapeRadius, maxIters );
logCount = gather(logCount);

n = 1000;
I = round(n*logCount);
offSet = -n*floor(min(I,[],'all')/n);
I = I + offSet;

inside = round(n*tflog(maxIters+1,escapeRadius,pow)) + offSet;
I(I == inside) = 100000;

imh.CData = I;
imh.Parent.CLim = [1 100000];
end % drawMandelbrot


function drawMandelbrotCrosshair( l, t, z0 )
hline = l(1);
vline = l(2);

vline.XData = real(z0)*[1 1];
hline.YData = imag(z0)*[1 1];
t.Position = [real(z0), imag(z0)];
t.String = num2str(z0);
end % drawMandelbrotCrosshair


function drawJulia( imh, z, c, animating, maxIterations )
escapeRadius = 20;

if animating && numel(z)>1e6
    z = z(1:2:end,1:2:end);
end

pow = 2;
logCount = arrayfun( @processJuliaSetElement, z, pow, c, escapeRadius, maxIterations );

logCount = gather(logCount);

n = 1000;
I = round(n*logCount);
offSet = -n*floor(min(I,[],'all')/n);
I = I + offSet;

inside = round(n*tflog(maxIterations+1,escapeRadius,pow)) + offSet;
I(I == inside) = 100000;

imh.CData = I;
imh.Parent.CLim = [1 100000];

end % drawJulia


function locations = makeLocationList()
breakpoints = [
    0.29
    0.47 + 0.157143i
    0.4442 + 0.3286i
    0.354911 + 0.585714i
    0.2103 + 0.5551i
    -0.0827 + 0.8355i
    -0.158482 + 1.042857i
    -0.5826 + 0.6143i
    -0.7533 + 0.1178i
    -1.008216 + 0.35i
    -1.25 + 0.2i
    -1.25
    0.29
    ];
numSteps = 10000;
N = numel(breakpoints);
re = interp1( 1:N, real( breakpoints ), linspace( 1, N, numSteps ) );
im = interp1( 1:N, imag( breakpoints ), linspace( 1, N, numSteps ) );
locations = complex( re, im );
end

