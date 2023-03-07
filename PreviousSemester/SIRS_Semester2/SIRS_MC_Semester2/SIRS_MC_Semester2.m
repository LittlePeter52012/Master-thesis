% &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
%    X + Z ---> 2X
%    X     ---> Y
%    Y     ---> Z
%  
%    dX/dt = k1*X*(1-X-Y) - k2*X 
%    dY/dt = k2*X - k3*Y
% 
%   X - infected
%   Y - recovered
% &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
function SIRS_MC(input)

clear;

global Nx Ny MCS
global N1 N2 N Sur
global h_fig1 FigClosed
global ESx ESy EmptySize EmptyShape EmptyFaceColor EmptyEdgeColor
global ASx ASy AdsSize AdsShape AdsFaceColor1 AdsFaceColor2 AdsEdgeColor1 AdsEdgeColor2

% Parameters ============================================================== 
Nx = 100;   % number of sites in the x-direction
Ny = 100;   % number of sites in the y-direction
N  = Nx*Ny; % amount of sites
C  = zeros(Ny, Nx, 'uint8'); % матрица для видео

Theta_1 = 0.0001;  % initial concentration of infected
Theta_2 = 0.0000;  % initial concentration of recovered

k1 = 4.0; 
k2 = 1.0; 
k3 = 0.1; 

kdif1 = 1.0; 
kdif2 = 1.0;

MCStep       = N; % один шаг МК = N попыток процессов 1,2,3
MCS_max      = 150; 
DrawStep     = 1; % в шагах МС
SaveDataStep = 1; % в шагах МС

SaveMP4 = 1;      % =0 if you want without MP4

% =========================================================================
% доли скоростей процессов
R_1 = k1/(k1 + k2 + k3 + kdif1 + kdif2);
R_2 = (k1 + k2)/(k1 + k2 + k3 + kdif1 + kdif2);
R_3 = (k1 + k2 + k3)/(k1 + k2 + k3 + kdif1 + kdif2);
R_4 = (k1 + k2 + k3 + kdif1)/(k1 + k2 + k3 + kdif1 + kdif2);

% =========================================================================
% начальное число частиц разных типов
N1 = round(Theta_1*N);  % amount of type-1 species x
N2 = round(Theta_2*N);  % amount of type-2 species y
N0 = N - N1 - N2;       % amount of type-3 species z

% =========================================================================
% поверхность
AdsShape =  [1, 1];
AdsFaceColor1 = 'red'; % infected
AdsEdgeColor1 = 'red';
AdsFaceColor2 = 'blue'; % recovered
AdsEdgeColor2 = 'blue';

map(1,:) = [0 1 0];       % RGB for z
map(2,:) = [1 0 0]; % RGB for x
map(3,:) = [0 0 1]; % RGB for y
colormap(map);

AdsSize = 0.75;

EmptyShape = [1, 1];
EmptyFaceColor = [0.9, 0.9, 0.9];
EmptyEdgeColor = 'black';
EmptySize = 0.98;  % 0...1

set(0,'Units','pixels');
scnsize = get(0,'ScreenSize');
h_fig1 = figure('Position', [0 0 scnsize(3) scnsize(4)], 'Units', 'pixels', 'CloseRequestFcn', @my_closereq);
daspect([1,1,1]);
axis off;

ESx = 0.5*(1-EmptySize);
ESy = 0.5*(1-EmptySize);
ASx = 0.5*(1-AdsSize);
ASy = 0.5*(1-AdsSize);
%%
cla;
%%
% =========================================================================
% фильм
if (SaveMP4 > 0)
    FileName0 = '1';
    writerObj = VideoWriter(FileName0,'MPEG-4');
    writerObj.FrameRate = 30;
    writerObj.Quality = 100;
    open(writerObj);
end

% =========================================================================
% define array of nearest neighbors (NN) таблица номеров первых соседей
% периодические граничные условия
k = 0;
Nei = zeros(4, N, 'int32');
for i = 1 : Ny
    for j = 1 : Nx
        k = k+1;	  
        % -----------------------------------------------------------------
        if (j < Nx) 
            Nei(1,k) = k + 1;  
        else 
            Nei(1,k) = k + 1 - Nx; 
        end
        % -----------------------------------------------------------------
        if (j > 1)  
            Nei(3,k) = k - 1;  
        else 
            Nei(3,k) = k - 1 + Nx; 
        end
        % -----------------------------------------------------------------
        if (i < Ny) 
            Nei(2,k) = k + Nx; 
        else 
            Nei(2,k) = k + Nx - N; 
        end
        % -----------------------------------------------------------------
        if (i > 1)  
            Nei(4,k) = k - Nx; 
        else 
            Nei(4,k) = k - Nx + N; 
        end
        % -----------------------------------------------------------------
    end
end

% =========================================================================
%  set lattice according to concentartions of type-1,2 species
Sur = zeros([N 1], 'int8');
N01 = N1;
N02 = N2;
while (N01 > 0) || (N02 > 0)
    i = randi(N); 
    if (Sur(i) == 0)
        if (N01 > 0) 
            Sur(i) = 1; 
            N01 = N01 - 1;
        else 
            if (N02 > 0) 
                Sur(i) = 2; 
                N02 = N02 - 1; 
            end
        end
    end
end

% =========================================================================
ylim([0 Ny]);
xlim([0 Nx]);
hold off;

DrawAll(); % рисуем решетку
drawnow;
FigClosed = 0;
 
% =========================================================================
% время и концентрации в файл
DataFileName = 'ndata8.dat';
fid = fopen(DataFileName, 'w+');
kt = 1;
tm(kt) = 0;
xg(kt) = N1/N;
yp(kt) = N2/N;
fprintf(fid, '%g  %g %g\r\n', tm(kt), xg(kt), yp(kt));

% =========================================================================
MCS   = 0; % счетчик шагов МК
SDS   = 0; % счетчик для выдачи числовой информации
DrawN = 0; % счетчик для выдачи поверхности
Trial = 0; % попытки

while (FigClosed == 0)  
    % random choice of occupied site
    i = randi(N); % выбор узла
    
    % random number for choice of a process
    RN = rand;
    Numb_proc = 0;
    if (RN <= R_1) 
        Numb_proc = 1; 
    else
        if ((RN > R_1) && (RN <= R_2)) 
            Numb_proc = 2; 
        else 
            if ((RN > R_2) && (RN <= R_3)) 
                Numb_proc = 3; 
            else 
                if ((RN > R_3) && (RN <= R_4)) 
                    Numb_proc = 4; 
                else
                    Numb_proc = 5; 
                end
            end
        end
    end
    % ---------------------------------------------------------------------
    switch Numb_proc
        case 1
            % reaction 1 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            Trial = Trial + 1;
            k = randi(4);
            j = Nei(k, i);
            if ((Sur(i) == 1) && (Sur(j) == 0)) 
                Sur(j) = 1;
                N1 = N1 + 1;
            end
        case 2
            % reaction 2 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            Trial = Trial + 1;
            if (Sur(i) == 1)
                Sur(i) = 2;
                N1 = N1 - 1;
                N2 = N2 + 1;
            end
        case 3
            % reaction 3 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            Trial = Trial + 1;
            if (Sur(i) == 2)
                Sur(i) = 0;
                N2 = N2 - 1;
            end
        case 4
            % diffusion x-z ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            k = randi(4);
            j = Nei(k, i);
            if ((Sur(i) == 1) && (Sur(j) == 0)) 
                SS = Sur(i);
                Sur(i) = Sur(j);
                Sur(j) = SS;
            end
        case 5
            % diffusion y-z ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            k = randi(4);
            j = Nei(k, i);
            if ((Sur(i) == 2) && (Sur(j) == 0)) 
                SS = Sur(i);
                Sur(i) = Sur(j);
                Sur(j) = SS;
           end
    end
    % ---------------------------------------------------------------------
    if (Trial >= MCStep)
        Trial = 0;
        MCS   = MCS + 1;
        SDS   = SDS + 1; 
        if (SDS >= SaveDataStep)
            SDS    = 0;
            kt     = kt + 1;
            tm(kt) = MCS;
            xg(kt) = N1/N;
            yp(kt) = N2/N;
            %fprintf(fid, '%g  %g %g\r\n', MCS/1000.0, N1/(N), N2/(N));
            fprintf(fid, '%g  %g %g\r\n', tm(kt), xg(kt), yp(kt));
        end
        DrawN = DrawN + 1;
        if (DrawN >= DrawStep)
            DrawN = 0;
            cla;
            DrawAll(); 
            if (SaveMP4 > 0)
                kk = 0;
                for j = 1 : Ny
                   for i = 1 : Nx
                       kk = kk + 1;
                       C(j,i) = Sur(kk);
                   end
                end
                F = im2frame(C, map);
                writeVideo(writerObj,F);
            end
        end
        if (MCS > MCS_max) 
            FigClosed = 1;
        end
    end
end
% -------------------------------------------------------------------------
if (SaveMP4 > 0)
    close(writerObj);
end
delete(gcf);
fclose(fid);
close all;
% -------------------------------------------------------------------------
figure(6);
  plot(tm(1:kt), xg(1:kt), 'red', 'LineWidth', 2); hold on
  plot(tm(1:kt), yp(1:kt), 'blue', 'LineWidth', 2);  hold on
  plot(tm(1:kt), 1-xg(1:kt)-yp(1:kt), 'k', 'LineWidth', 2);
  legend ('\theta_I', '\theta_R', '\theta_S' )
  % xlim([0 tmax_h]);
  ylim([0 1]);
  xlabel('MCS', 'FontSize', 14); ylabel('\theta', 'FontSize', 14); hold on;
  title('SIRS', 'FontSize', 14); hold on; grid on; 

% &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
function my_closereq(src,evnt)
global h_fig1 FigClosed
   selection = questdlg('Close This Figure?', '','Yes', 'No', 'Yes'); 
   switch selection, ... 
      case 'Yes', ...
         FigClosed = 1;
      case 'No'
      return 
   end

% &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
function DrawSite(i,j,V)
 global Nx Ny MCS
 global ESx ESy EmptySize EmptyShape EmptyFaceColor EmptyEdgeColor
 global ASx ASy AdsSize AdsShape AdsFaceColor1 AdsFaceColor2 AdsEdgeColor1 AdsEdgeColor2
 ycur = Ny - i;
 xcur = j - 1;   
%  if (V == 0)
%    rectangle('Position', [xcur+ESx, ycur+ESy, EmptySize, EmptySize], 'Curvature', EmptyShape, 'FaceColor', EmptyFaceColor, 'EdgeColor', EmptyEdgeColor);
%  end
 if (V == 1)
   rectangle('Position', [xcur+ASx, ycur+ASy, AdsSize, AdsSize], 'Curvature', AdsShape, 'FaceColor', AdsFaceColor1, 'EdgeColor', AdsEdgeColor1);
 end
 if (V == 2)
   rectangle('Position', [xcur+ASx, ycur+ASy, AdsSize, AdsSize], 'Curvature', AdsShape, 'FaceColor', AdsFaceColor2, 'EdgeColor', AdsEdgeColor2);
 end

% &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
function DrawAll()
 global Nx Ny MCS
 global N1 N2 N Sur
    rectangle('Position', [0, 0, Nx, Ny], 'Curvature', [0, 0],'FaceColor', [0.99, 0.99, 0.99], 'EdgeColor', [0 0 0], 'LineWidth', 2);
    title(['MCS = ' num2str(MCS,'%d') '    X = ' num2str(N1/N,'%8.4f') ...
                                      '    Y = ' num2str(N2/N,'%8.4f') ...
                                      '    Z = ' num2str((N-N1-N2)/N,'%8.4f')]);
    k = 0;
    for i = 1 : Ny
      for j = 1 : Nx
        k = k + 1;
        DrawSite(i, j, Sur(k));
      end
    end
    drawnow;

% &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
