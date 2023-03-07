%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
function MC_square_3
%==========================================================================
% Модель SIR на квадратной решётке, кинетический метод МК
%**************************************************************************
clear;
%**************************************************************************
global k1 k2 k3 d1 d2 d3
global Nx Ny N 
global x0 y0 RandSeed N1ini N2ini
global Latt Nei Latt_cl Latt_cl_n
global class_MC numb_class_MC
global t0 t1 t_end dt_fig res
global h_fig1 FigClosed
%**************************************************************************
% значения скоростей
k1 = 1.0;
k2 = 1.0; 
k3 = 0.1;
d1 = 10.0;
d2 = 10.0;
d3 = 10.0;
%--------------------------------------------------------------------------
% размеры решётки, общее число узлов (ячеек) решётки
Nx = 200; Ny = 200; N = Nx*Ny; 
% начальая концентрация заболевших (infected)
x0 = 0.0001; 
if(x0 > 1) 
    x0 = 1; 
end
% начальная концентрация выздоровевших с иммунитетом (recovered)
y0 = 0.0; 
if (x0 + y0 > 1) 
    y0 = 1 - x0; 
end
% число для инициализации датчика случайных чисел
RandSeed = 2;

%--------------------------------------------------------------------------
% временной интервал
t0    = 0;
t1    = 30; 
t_end = t1;

%--------------------------------------------------------------------------
% описание классов для квадратной решётки при трёх состояниях узлов
class_def;

%--------------------------------------------------------------------------
% задание массива Nei - номеров ближайших соседних узлов с учётом
% периодических гр. условий
nei_def;

%--------------------------------------------------------------------------
% начальное состояние поверхности
ini_def;

%--------------------------------------------------------------------------
% визуализация
dt_fig = 0.1;

% поверхность
AdsShape =  [1, 1];
AdsFaceColor1 = 'red'; % infected
AdsEdgeColor1 = 'red';
AdsFaceColor2 = 'blue'; % recovered
AdsEdgeColor2 = 'blue';

AdsSize = 0.75;

EmptyShape     = [1, 1];
EmptyFaceColor = [0.9, 0.9, 0.9];
EmptyEdgeColor = 'black';
EmptySize      = 0.98;  % 0...1

set(0,'Units','pixels');
scnsize = get(0,'ScreenSize');
h_fig1  = figure('Position', [0 0 scnsize(3) scnsize(4)], 'Units', 'pixels', 'CloseRequestFcn', @my_closereq);
daspect([1,1,1]);
axis off;

ESx = 0.5*(1-EmptySize);
ESy = 0.5*(1-EmptySize);
ASx = 0.5*(1-AdsSize);
ASy = 0.5*(1-AdsSize);

FigClosed = 0;

cla;
%--------------------------------------------------------------------------
% формирование массивов номеров узлов для всех классов 
list_class_def;

%--------------------------------------------------------------------------
% вычисления
KMC_proc(x0, y0);

%--------------------------------------------------------------------------
% графики
% массив вывода результатов
plot_MC

% delete(gcf);
% fclose(fid);
% close all;

%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
function ini_def
%==========================================================================
% Начальное заполнение поверхности
%**************************************************************************
global Nx Ny N
global x0 y0 RandSeed N1ini N2ini
global Latt Nei Latt_cl Latt_cl_n
%**************************************************************************
% массив Latt содержит текущее состояние узлов решётки
Latt = zeros(N, 1, 'int32'); 
%--------------------------------------------------------------------------
% инициализация датчика
rng(RandSeed, 'twister'); 
%--------------------------------------------------------------------------
% случайное начальное распределение для заданной концентрации X
N01 = round(x0*N);
N1ini = N01;
while (N01 > 0)
    i = randi(N);
    if (Latt(i) == 0)
        Latt(i) = 1;
        N01 = N01 - 1;
    end
end
%--------------------------------------------------------------------------
% случайное начальное распределение для заданной концентрации Y
N02 = round(y0*N);
N2ini = N02;
while (N02 > 0)
    i = randi(N);
    if (Latt(i) == 0)
        Latt(i) = 2;
        N02 = N02 - 1;
    end
end

%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
function fig_surf(MTime, x, y, z)
%==========================================================================
% Изображение поверхности
%**************************************************************************
global Nx Ny N
global Latt Nei Latt_cl Latt_cl_n
global h_fig1 FigClosed
%**************************************************************************
C = zeros(Ny, Nx, 'uint8');
%--------------------------------------------------------------------------
map(1,:) = [1 1 1]; % RGB for z
map(2,:) = [1 0 0]; % RGB for x
map(3,:) = [0 0 1]; % RGB for y
colormap(map);

%--------------------------------------------------------------------------
% set(0,'Units','pixels');
% scnsize = get(0,'ScreenSize');
% figure('Position', [1 1 scnsize(3) scnsize(4)-100]);
%--------------------------------------------------------------------------
k = 0;
for j = 1 : Ny
    for i = 1 : Nx
         k = k + 1;
         C(j,i) = Latt(k);
    end
end
%--------------------------------------------------------------------------
image(C);
box on
axis image
        
set(gca,'XTickLabel',{});
set(gca,'XTick',[]);
set(gca,'YTickLabel',{});
set(gca,'YTick',[]);
        
title(['time = ' num2str(MTime,'%.4f'),',    x = ' num2str(x,'%.4f'), ...
       ',    y = ' num2str(y,'%.4f') , ',    z = ' num2str(z,'%.4f')]); 
drawnow;

%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
function class_def
%==========================================================================
% Описание классов для квадратной решётки при трёх состояниях узлов
%**************************************************************************
global k1 k2 k3 d1 d2 d3
global Nx Ny N
global class_MC numb_class_MC
%**************************************************************************
List = zeros(N, 1, 'int32');
% class_MC(1,66) = struct('code', 0.0, ...
%                         'rates', [0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0], ...
%                         'sum_rates', 0.0, ...
%                         'numb_rates', 0.0, ...
%                         'list', List, ... );
%                         'numb_list', ..., 0, 
%**************************************************************************
class_MC(1).code         = 00001;
class_MC(1).rates        = [k2 ...
                            k2+k1 k2+2*k1 k2+3*k1 k2+4*k1 ...
                            k2+4*k1+d1 k2+4*k1+2*d1 k2+4*k1+3*d1 k2+4*k1+4*d1];
class_MC(1).numb_rates   = 9;
class_MC(1).sum_rates    = class_MC(1).rates(class_MC(1).numb_rates);
class_MC(1).rates        = class_MC(1).rates/class_MC(1).sum_rates;
class_MC(1).list         = List;
class_MC(1).numb_list    = 0;
% a = class_MC(1).rates
%**************************************************************************
class_MC(2).code         = 00201;
class_MC(2).rates        = [k2 ...
                            k2+k1 k2+2*k1 k2+3*k1 ...
                            k2+3*k1+d1 k2+3*k1+2*d1 k2+3*k1+3*d1 ...
                            k2+3*k1+3*d1+d2];
class_MC(2).numb_rates   = 8;
class_MC(2).sum_rates    = class_MC(2).rates(class_MC(2).numb_rates);
class_MC(2).rates        = class_MC(2).rates/class_MC(2).sum_rates;
class_MC(2).list         = List;
class_MC(2).numb_list    = 0;
% a = class_MC(2).rates
%--------------------------------------------------------------------------
class_MC(3)              = class_MC(2);
class_MC(3).code         = 00021;
%--------------------------------------------------------------------------
class_MC(4)              = class_MC(2);
class_MC(4).code         = 20001;
%--------------------------------------------------------------------------
class_MC(5)              = class_MC(2);
class_MC(5).code         = 02001;
%**************************************************************************
class_MC(6).code         = 00101;
class_MC(6).rates        = [k2 ...
                            k2+k1 k2+2*k1 k2+3*k1 ...
                            k2+3*k1+d1 k2+3*k1+2*d1 k2+3*k1+3*d1];
class_MC(6).numb_rates   = 7;
class_MC(6).sum_rates    = class_MC(6).rates(class_MC(6).numb_rates);
class_MC(6).rates        = class_MC(6).rates/class_MC(6).sum_rates;
class_MC(6).list         = List;
class_MC(6).numb_list    = 0;
% a = class_MC(6).rates
%--------------------------------------------------------------------------
class_MC(7)              = class_MC(6);
class_MC(7).code         = 00011;
%--------------------------------------------------------------------------
class_MC(8)              = class_MC(6);
class_MC(8).code         = 10001;
%--------------------------------------------------------------------------
class_MC(9)              = class_MC(6);
class_MC(9).code         = 01001;
%**************************************************************************
class_MC(10).code        = 00221;
class_MC(10).rates       = [k2 ...
                            k2+k1 k2+2*k1 ...
                            k2+2*k1+d1 k2+2*k1+2*d1 ...
                            k2+2*k1+2*d1+d2 k2+2*k1+2*d1+2*d2];
class_MC(10).numb_rates  = 7;
class_MC(10).sum_rates   = class_MC(10).rates(class_MC(10).numb_rates);
class_MC(10).list        = List;
class_MC(10).numb_list   = 0;
%--------------------------------------------------------------------------
class_MC(11)             = class_MC(10);
class_MC(11).code        = 20021;
%--------------------------------------------------------------------------
class_MC(12)             = class_MC(10);
class_MC(12).code        = 22001;
%--------------------------------------------------------------------------
class_MC(13)             = class_MC(10);
class_MC(13).code        = 02201;
%--------------------------------------------------------------------------
class_MC(14)             = class_MC(10);
class_MC(14).code        = 20201;
%--------------------------------------------------------------------------
class_MC(15)             = class_MC(10);
class_MC(15).code        = 02021;
%**************************************************************************
class_MC(16).code        = 00111;
class_MC(16).rates       = [k2 ...
                            k2+k1 k2+2*k1 ...
                            k2+2*k1+d1 k2+2*k1+2*d1];
class_MC(16).numb_rates  = 5;
class_MC(16).sum_rates   = class_MC(16).rates(class_MC(16).numb_rates);
class_MC(16).rates       = class_MC(16).rates/class_MC(16).sum_rates;
class_MC(16).list        = List;
class_MC(16).numb_list   = 0;
% a = class_MC(16).rates
%--------------------------------------------------------------------------
class_MC(17)             = class_MC(16);
class_MC(17).code        = 10011;
%--------------------------------------------------------------------------
class_MC(18)             = class_MC(16);
class_MC(18).code        = 11001;
%--------------------------------------------------------------------------
class_MC(19)             = class_MC(16);
class_MC(19).code        = 01101;
%--------------------------------------------------------------------------
class_MC(20)             = class_MC(16);
class_MC(20).code        = 10101;
%--------------------------------------------------------------------------
class_MC(21)             = class_MC(16);
class_MC(21).code        = 01011;
%**************************************************************************
class_MC(22).code        = 00121;
class_MC(22).rates       = [k2 ...
                            k2+k1 k2+2*k1 ...
                            k2+2*k1+d1 k2+2*k1+2*d1 ...
                            k2+2*k1+2*d1+d2];
class_MC(22).numb_rates  = 6;
class_MC(22).sum_rates   = class_MC(22).rates(class_MC(22).numb_rates);
class_MC(22).rates       = class_MC(22).rates/class_MC(22).sum_rates;
class_MC(22).list        = List;
class_MC(22).numb_list   = 0;
% a = class_MC(22).rates
%--------------------------------------------------------------------------
class_MC(23)             = class_MC(22);
class_MC(23).code        = 20011;
%--------------------------------------------------------------------------
class_MC(24)             = class_MC(22);
class_MC(24).code        = 12001;
%--------------------------------------------------------------------------
class_MC(25)             = class_MC(22);
class_MC(25).code        = 01201;
%--------------------------------------------------------------------------
class_MC(26)             = class_MC(22);
class_MC(26).code        = 20101;
%--------------------------------------------------------------------------
class_MC(27)             = class_MC(22);
class_MC(27).code        = 02011;
%--------------------------------------------------------------------------
class_MC(28)             = class_MC(22);
class_MC(28).code        = 00211;
%--------------------------------------------------------------------------
class_MC(29)             = class_MC(22);
class_MC(29).code        = 10021;
%--------------------------------------------------------------------------
class_MC(30)             = class_MC(22);
class_MC(30).code        = 21001;
%--------------------------------------------------------------------------
class_MC(31)             = class_MC(22);
class_MC(31).code        = 02101;
%--------------------------------------------------------------------------
class_MC(32)             = class_MC(22);
class_MC(32).code        = 10201;
%--------------------------------------------------------------------------
class_MC(33)             = class_MC(22);
class_MC(33).code        = 01021;
%**************************************************************************
class_MC(34).code        = 20221;
class_MC(34).rates       = [k2 ...
                            k2+k1 ...
                            k2+k1+d1 ...
                            k2+k1+d1+d2 k2+k1+d1+2*d2 k2+k1+d1+3*d2];
class_MC(34).numb_rates  = 6;
class_MC(34).sum_rates   = class_MC(34).rates(class_MC(34).numb_rates);
class_MC(34).rates       = class_MC(34).rates/class_MC(34).sum_rates;
class_MC(34).list        = List;
class_MC(34).numb_list   = 0;
% a = class_MC(34).rates
%--------------------------------------------------------------------------
class_MC(35)             = class_MC(34);
class_MC(35).code        = 22021;
%--------------------------------------------------------------------------
class_MC(36)             = class_MC(34);
class_MC(36).code        = 22201;
%--------------------------------------------------------------------------
class_MC(37)             = class_MC(34);
class_MC(37).code        = 02221;
%**************************************************************************
class_MC(38).code        = 10111;
class_MC(38).rates       = [k2 ...
                            k2+k1 ...
                            k2+k1+d1];
class_MC(38).numb_rates  = 3;
class_MC(38).sum_rates   = class_MC(38).rates(class_MC(38).numb_rates);
class_MC(38).rates       = class_MC(38).rates/class_MC(38).sum_rates;
class_MC(38).list        = List;
class_MC(38).numb_list   = 0;
% a = class_MC(38).rates
%--------------------------------------------------------------------------
class_MC(39)             = class_MC(38);
class_MC(39).code        = 11011;
%--------------------------------------------------------------------------
class_MC(40)             = class_MC(38);
class_MC(40).code        = 11101;
%--------------------------------------------------------------------------
class_MC(41)             = class_MC(38);
class_MC(41).code        = 01111;
%**************************************************************************
class_MC(42).code        = 20121;
class_MC(42).rates       = [k2 ...
                            k2+k1 ...
                            k2+k1+d1 ...
                            k2+k1+d1+d2 k2+k1+d1+2*d2];
class_MC(42).numb_rates  = 5;
class_MC(42).sum_rates   = class_MC(42).rates(class_MC(42).numb_rates);
class_MC(42).rates       = class_MC(42).rates/class_MC(42).sum_rates;
class_MC(42).list        = List;
class_MC(42).numb_list   = 0;
% a = class_MC(42).rates
%--------------------------------------------------------------------------
class_MC(43)             = class_MC(42);
class_MC(43).code        = 22011;
%--------------------------------------------------------------------------
class_MC(44)             = class_MC(42);
class_MC(44).code        = 12201;
%--------------------------------------------------------------------------
class_MC(45)             = class_MC(42);
class_MC(45).code        = 02211;
%--------------------------------------------------------------------------
class_MC(46)             = class_MC(42);
class_MC(46).code        = 20211;
%--------------------------------------------------------------------------
class_MC(47)             = class_MC(42);
class_MC(47).code        = 12021;
%--------------------------------------------------------------------------
class_MC(48)             = class_MC(42);
class_MC(48).code        = 21201;
%--------------------------------------------------------------------------
class_MC(49)             = class_MC(42);
class_MC(49).code        = 02121;
%--------------------------------------------------------------------------
class_MC(50)             = class_MC(42);
class_MC(50).code        = 10221;
%--------------------------------------------------------------------------
class_MC(51)             = class_MC(42);
class_MC(51).code        = 21021;
%--------------------------------------------------------------------------
class_MC(52)             = class_MC(42);
class_MC(52).code        = 22101;
%--------------------------------------------------------------------------
class_MC(53)             = class_MC(42);
class_MC(53).code        = 01221;
%**************************************************************************
class_MC(54).code        = 20111;
class_MC(54).rates       = [k2 ...
                            k2+k1 ...
                            k2+k1+d1 ...
                            k2+k1+d1+d2];
class_MC(54).numb_rates  = 4;
class_MC(54).sum_rates   = class_MC(54).rates(class_MC(54).numb_rates);
class_MC(54).rates       = class_MC(54).rates/class_MC(54).sum_rates;
class_MC(54).list        = List;
class_MC(54).numb_list   = 0;
% a = class_MC(54).rates
%--------------------------------------------------------------------------
class_MC(55)             = class_MC(54);
class_MC(55).code        = 12011;
%--------------------------------------------------------------------------
class_MC(56)             = class_MC(54);
class_MC(56).code        = 11201;
%--------------------------------------------------------------------------
class_MC(57)             = class_MC(54);
class_MC(57).code        = 02111;
%--------------------------------------------------------------------------
class_MC(58)             = class_MC(54);
class_MC(58).code        = 10211;
%--------------------------------------------------------------------------
class_MC(59)             = class_MC(54);
class_MC(59).code        = 11021;
%--------------------------------------------------------------------------
class_MC(60)             = class_MC(54);
class_MC(60).code        = 21101;
%--------------------------------------------------------------------------
class_MC(61)             = class_MC(54);
class_MC(61).code        = 01121;
%--------------------------------------------------------------------------
class_MC(62)             = class_MC(54);
class_MC(62).code        = 10121;
%--------------------------------------------------------------------------
class_MC(63)             = class_MC(54);
class_MC(63).code        = 21011;
%--------------------------------------------------------------------------
class_MC(64)             = class_MC(54);
class_MC(64).code        = 12101;
%--------------------------------------------------------------------------
class_MC(65)             = class_MC(54);
class_MC(65).code        = 01211;
%**************************************************************************
class_MC(66).code        = 11111;
class_MC(66).rates       = [k2];
class_MC(66).numb_rates  = 1;
class_MC(66).sum_rates   = class_MC(66).rates(class_MC(66).numb_rates);
class_MC(66).rates       = class_MC(66).rates/class_MC(66).sum_rates;
class_MC(66).list        = List;
class_MC(66).numb_list   = 0;
% a = class_MC(66).rates
%**************************************************************************
class_MC(67).code        = 22221;
class_MC(67).rates       = [k2 ...
                            k2+d2 ...
                            k2+2*d2 ...
                            k2+3*d2 ...
                            k2+4*d2];
class_MC(67).numb_rates  = 5;
class_MC(67).sum_rates   = class_MC(67).rates(class_MC(67).numb_rates);
class_MC(67).rates       = class_MC(67).rates/class_MC(67).sum_rates;
class_MC(67).list        = List;
class_MC(67).numb_list   = 0;
% a = class_MC(67).rates
%**************************************************************************
class_MC(68).code        = 21111;
class_MC(68).rates       = [k2 ...
                            k2+d2];
class_MC(68).numb_rates  = 2;
class_MC(68).sum_rates   = class_MC(68).rates(class_MC(68).numb_rates);
class_MC(68).rates       = class_MC(68).rates/class_MC(68).sum_rates;
class_MC(68).list        = List;
class_MC(68).numb_list   = 0;
% a = class_MC(68).rates
%--------------------------------------------------------------------------
class_MC(69)             = class_MC(68);
class_MC(69).code        = 11121;
%--------------------------------------------------------------------------
class_MC(70)             = class_MC(68);
class_MC(70).code        = 11211;
%--------------------------------------------------------------------------
class_MC(71)             = class_MC(68);
class_MC(71).code        = 12111;
%**************************************************************************
class_MC(72).code        = 22111;
class_MC(72).rates       = [k2 ...
                            k2+d2 ...
                            k2+2*d2];
class_MC(72).numb_rates  = 3;
class_MC(72).sum_rates   = class_MC(72).rates(class_MC(72).numb_rates);
class_MC(72).rates       = class_MC(72).rates/class_MC(72).sum_rates;
class_MC(72).list        = List;
class_MC(72).numb_list   = 0;
% a = class_MC(72).rates
%--------------------------------------------------------------------------
class_MC(73)             = class_MC(72);
class_MC(73).code        = 21121;
%--------------------------------------------------------------------------
class_MC(74)             = class_MC(72);
class_MC(74).code        = 11221;
%--------------------------------------------------------------------------
class_MC(75)             = class_MC(72);
class_MC(75).code        = 12211;
%--------------------------------------------------------------------------
class_MC(76)             = class_MC(72);
class_MC(76).code        = 12121;
%--------------------------------------------------------------------------
class_MC(77)             = class_MC(72);
class_MC(77).code        = 21211;
%**************************************************************************
class_MC(78).code        = 12221;
class_MC(78).rates       = [k2 ...
                            k2+d2 ...
                            k2+2*d2 ...
                            k2+3*d2];
class_MC(78).numb_rates  = 4;
class_MC(78).sum_rates   = class_MC(78).rates(class_MC(78).numb_rates);
class_MC(78).rates       = class_MC(78).rates/class_MC(78).sum_rates;
class_MC(78).list        = List;
class_MC(78).numb_list   = 0;
% a = class_MC(78).rates
%--------------------------------------------------------------------------
class_MC(79)             = class_MC(78);
class_MC(79).code        = 22211;
%--------------------------------------------------------------------------
class_MC(80)             = class_MC(78);
class_MC(80).code        = 22121;
%--------------------------------------------------------------------------
class_MC(81)             = class_MC(78);
class_MC(81).code        = 21221;
%**************************************************************************
class_MC(82).code        = 00002;
class_MC(82).rates       = [k3];
class_MC(82).numb_rates  = 1;
class_MC(82).sum_rates   = class_MC(82).rates(class_MC(82).numb_rates);
class_MC(82).rates       = class_MC(82).rates/class_MC(82).sum_rates;

class_MC(82).list        = List;
class_MC(82).numb_list   = 0;
% a = class_MC(82).rates
%**************************************************************************
class_MC(83).code        = 00012;
class_MC(83).rates       = [k3 ...
                            k3+d3];
class_MC(83).numb_rates  = 2;
class_MC(83).sum_rates   = class_MC(83).rates(class_MC(83).numb_rates);
class_MC(83).rates       = class_MC(83).rates/class_MC(83).sum_rates;

class_MC(83).list        = List;
class_MC(83).numb_list   = 0;
% a = class_MC(83).rates
%**************************************************************************
class_MC(84).code        = 00022;
class_MC(84).rates       = [k3 ...
                            k3+d3 k3+2*d3];
class_MC(84).numb_rates  = 3;
class_MC(84).sum_rates   = class_MC(84).rates(class_MC(84).numb_rates);
class_MC(84).rates       = class_MC(84).rates/class_MC(84).sum_rates;

class_MC(84).list        = List;
class_MC(84).numb_list   = 0;
% a = class_MC(84).rates
%**************************************************************************
class_MC(85).code        = 00032;
class_MC(85).rates       = [k3 ...
                            k3+d3 k3+2*d3 k3+3*d3];
class_MC(85).numb_rates  = 4;
class_MC(85).sum_rates   = class_MC(85).rates(class_MC(85).numb_rates);
class_MC(85).rates       = class_MC(85).rates/class_MC(85).sum_rates;

class_MC(85).list        = List;
class_MC(85).numb_list   = 0;
% a = class_MC(85).rates
%**************************************************************************
class_MC(86).code        = 00042;
class_MC(86).rates       = [k3 ...
                            k3+d3 k3+2*d3 k3+3*d3 k3+4*d3];
class_MC(86).numb_rates  = 5;
class_MC(86).sum_rates   = class_MC(86).rates(class_MC(86).numb_rates);
class_MC(86).rates       = class_MC(86).rates/class_MC(86).sum_rates;

class_MC(86).list        = List;
class_MC(86).numb_list   = 0;
% a = class_MC(86).rates
%**************************************************************************
numb_class_MC = 86;

%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
function nei_def
%==========================================================================
% Задание массива Nei - номеров ближайших соседних узлов с учётом
% периодических гр. условий
%**************************************************************************
global Nx Ny N
global Latt Nei Latt_cl Latt_cl_n
%**************************************************************************
k = 0;
Nei = zeros(4, N, 'int32');
for i = 1 : Ny  % перебор по строкам
    for j = 1 : Nx  % перебор по столбцам
        k = k+1;
        % первый сосед ----------------------------------------------------
        if (j < Nx)
            Nei(1,k) = k + 1;
        else
            Nei(1,k) = k + 1 - Nx; % периодические гр. условия
        end
        % третий сосед ----------------------------------------------------       
        if (j > 1)
            Nei(3,k) = k - 1;
        else
            Nei(3,k) = k - 1 + Nx; % периодические гр. условия
        end
        % второй сосед ----------------------------------------------------       
        if (i < Ny)
            Nei(2,k) = k + Nx;
        else
            Nei(2,k) = k + Nx - N; % периодические гр. условия
        end
        % четвёртый сосед -------------------------------------------------       
        if (i > 1)
            Nei(4,k) = k - Nx;
        else
            Nei(4,k) = k - Nx + N; % периодические гр. условия
        end        
    end
end

%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
function list_class_def
%==========================================================================
% Формирование массивов номеров узлов для всех классов в начале расчётов
%**************************************************************************
global Nx Ny N
global Latt Nei Latt_cl Latt_cl_n
global class_MC numb_class_MC
global x0 y0 RandSeed N1ini N2ini
%**************************************************************************
% массив Latt_cl содержит номер класса каждого узла
Latt_cl   = zeros(N, 1, 'int32'); 
% массив Latt_cl_n содержит номер в списке элементов класса
Latt_cl_n = zeros(N, 1, 'int32'); 
%--------------------------------------------------------------------------
for i = 1 : N  % перебор по узлам
    if (Latt(i) == 1)
        a = zeros(1, 1, 'int32'); % кодовое число класса
        % вычисляем кодовое число конфигурации соседей
        a = Latt(Nei(1,i))*10000 + ...
            Latt(Nei(2,i))*1000 + ...
            Latt(Nei(3,i))*100 + ...
            Latt(Nei(4,i))*10 + 1;
        % ищем нужный класс
        for j = 1 : numb_class_MC
            if (a == class_MC(j).code)
                class_MC(j).numb_list = class_MC(j).numb_list + 1; 
                class_MC(j).list(class_MC(j).numb_list) = i;
                Latt_cl(i)   = j;
                Latt_cl_n(i) = class_MC(j).numb_list;
                break
            end
        end
    end
    if (Latt(i) == 2)
        kk = 0;
        for j = 1 : 4
            if(Latt(Nei(j,i)) == 0)
                kk = kk + 1;
            end
        end
        j = 82;
        if (kk == 1) 
            j = 83; 
        end
        if (kk == 2) 
            j = 84; 
        end
        if (kk == 3) 
            j = 85; 
        end
        if (kk == 4) 
            j = 86; 
        end

        class_MC(j).numb_list = class_MC(j).numb_list + 1; 
        class_MC(j).list(class_MC(j).numb_list) = i;
        Latt_cl(i)   = j;
        Latt_cl_n(i) = class_MC(j).numb_list;
    end
end
%--------------------------------------------------------------------------
% % Проверка
% nn = 0;
% for i = 1 : numb_class_MC
%     b = class_MC(i).numb_list;
%     nn = nn + b; 
% end
% nnini = N1ini+N2ini 
% nn

%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
function KMC_proc(x0, y0)
%==========================================================================
% Кинетический алгоритм Monte Carlo
%**************************************************************************
global Latt Nei Latt_cl Latt_cl_n
global class_MC numb_class_MC
global t0 t1 t_end dt_fig res
global Nx Ny N
global h_fig1 FigClosed
global x0 y0 RandSeed N1ini N2ini
%**************************************************************************
res = 0;
t_curr = t0;
t_curr_fig = t0 + dt_fig;
res(1,1) =  t_curr; 
res(1,2) =  x0; 
res(1,3) =  y0; 
res(1,4) =  1 - res(1,2) - res(1,3); 
n_res    = 1;

while ((FigClosed == 0) && (t_curr <= t1))
    t_end = t_curr;
    % суммарная скорость всех процессов -----------------------------------
    V = 0.0;
    for j = 1 : numb_class_MC
        V = V + class_MC(j).numb_list*class_MC(j).sum_rates;
    end
    if (V == 0)
        break
    end
    % шаг по времени ------------------------------------------------------
    random1 = rand;
    t_delta = -log(random1)/V;
    t_curr  = t_curr + t_delta;

    % выбор номера класса Nc ----------------------------------------------
    random2 = rand*V;
    Nc = 0;
    while(random2 > 0)
        Nc = Nc + 1;
        random2 = random2 - class_MC(Nc).numb_list*class_MC(Nc).sum_rates;        
    end

    % выбор номера узла в классе Ns ---------------------------------------
    random3 = randi(class_MC(Nc).numb_list);
    Ns = random3;

    a = class_MC(Nc)
    % выбор номера процесса Np --------------------------------------------
    random4 = rand;
    Np = 1;
    for j = 1 : class_MC(Nc).numb_rates-1
        if(random4 > class_MC(Nc).rates(j))
            Np = j+1;
        end
    end
    % реализация процесса -------------------------------------------------
    [NN] = proc_realization(Nc, Ns, Np);

    % визуализация --------------------------------------------------------
    if(t_curr > t_curr_fig) 
        x = 0;
        y = 0;
        for i = 1 : N
            if (Latt(i) == 1) 
                x = x + 1; 
            end
            if (Latt(i) == 2) 
                y = y + 1; 
            end
        end
        x = x/N; y = y/N; z = 1 - x - y;
        fig_surf(t_curr, x, y, z);
        t_curr_fig = t_curr_fig + dt_fig;

        n_res = n_res + 1;
        res(n_res,1) =  t_curr; 
        res(n_res,2) =  x; 
        res(n_res,3) =  y; 
        res(n_res,4) =  1 - x - y; 
    end

    % локальный пересчёт скоростей ----------------------------------------
    % узел NN 
    local_recalc(NN);
    % 4 соседа узла NN 
    NN1 = Nei(1,NN);
    NN2 = Nei(2,NN);
    NN3 = Nei(3,NN);
    NN4 = Nei(4,NN);
    local_recalc(NN1);
    local_recalc(NN2);
    local_recalc(NN3);
    local_recalc(NN4);
    % три соседа узла NN1 
    NN5 = Nei(4,NN1);
    NN6 = Nei(1,NN1);
    NN7 = Nei(2,NN1);
    local_recalc(NN5);    
    local_recalc(NN6);
    local_recalc(NN7);
    % два соседа узла NN2 
    NN8 = Nei(2,NN2);
    NN9 = Nei(3,NN2);
    local_recalc(NN8);
    local_recalc(NN9);
    % два соседа узла NN3 
    NN10 = Nei(3,NN3);
    NN11 = Nei(4,NN3);
    local_recalc(NN10);
    local_recalc(NN11);
    % один сосед узла NN4 
    NN12 = Nei(4,NN4);
    local_recalc(NN12);
    
%     % Проверка
%     nn = 0;
%     for i = 1 : numb_class_MC
%         b = class_MC(i).numb_list;
%         nn = nn + b; 
%     end
%     kk1 = 0;
%     kk2 = 0;
%     for i = 1 : N
%         if(Latt(i) == 1)
%             kk1 = kk1 + 1;
%         end
%         if(Latt(i) == 2)
%             kk2 = kk2 + 1;
%         end
%     end
%     nnini = kk1+kk2
%     nn

end
delete(gcf);
% fclose(fid);
% close all;

%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
function NN = proc_realization(Nc, Ns, Np)
%==========================================================================
% Реализация процесса
% Nc - номер класса, Ns - номер элемента в классе, Np - номер процесса
%**************************************************************************
global Latt Nei Latt_cl Latt_cl_n
global class_MC numb_class_MC
%**************************************************************************
% номер выбранного узла, номера узлов соседей выбранного узла 
NN  = class_MC(Nc).list(Ns);
NN1 = Nei(1,NN);
NN2 = Nei(2,NN);
NN3 = Nei(3,NN);
NN4 = Nei(4,NN);
%--------------------------------------------------------------------------
switch Nc % выбираем класс
   case 1 % класс 1; 9 процессов ------------------------------------------
      switch Np
          case 1 % k2 
              Latt(NN) = 2;
          case 2 % k1 направо
              Latt(NN1) = 1;
          case 3 % k1 вниз
              Latt(NN2) = 1;
          case 4 % k1 налево
              Latt(NN3) = 1;
          case 5 % k1 вверх
              Latt(NN4) = 1;
          case 6 % d1 направо
              Latt(NN) = 0; Latt(NN1) = 1;
          case 7 % d1 вниз
              Latt(NN) = 0; Latt(NN2) = 1;
          case 8 % d1 налево
              Latt(NN) = 0; Latt(NN3) = 1;
          case 9 % d1 вверх
              Latt(NN) = 0; Latt(NN4) = 1;
          otherwise
              err = 'Error 1 class !'
              pause
      end

   case 2 % класс 2; 8 процессов ------------------------------------------
      switch Np
          case 1 % k2 
              Latt(NN) = 2;
          case 2 % k1 направо
              Latt(NN1) = 1;
          case 3 % k1 вниз
              Latt(NN2) = 1;
          case 4 % k1 вверх
              Latt(NN4) = 1;
          case 5 % d1 направо
              Latt(NN) = 0; Latt(NN1) = 1;
          case 6 % d1 вниз
              Latt(NN) = 0; Latt(NN2) = 1;
          case 7 % d1 вверх
              Latt(NN) = 0; Latt(NN4) = 1;
          case 8 % d2 налево
              Latt(NN) = 2; Latt(NN3) = 1;
          otherwise
              err = 'Error 2 class !'
              pause
      end

   case 3 % класс 3; 8 процессов ------------------------------------------
      switch Np
          case 1 % k2 
              Latt(NN) = 2;
          case 2 % k1 направо
              Latt(NN1) = 1;
          case 3 % k1 вниз
              Latt(NN2) = 1;
          case 4 % k1 налево
              Latt(NN3) = 1;
          case 5 % d1 направо
              Latt(NN) = 0; Latt(NN1) = 1;
          case 6 % d1 вниз
              Latt(NN) = 0; Latt(NN2) = 1;
          case 7 % d1 налево
              Latt(NN) = 0; Latt(NN3) = 1;
          case 8 % d2 вверх
              Latt(NN) = 2; Latt(NN4) = 1;
          otherwise
              err = 'Error 3 class !'
              pause
      end

   case 4 % класс 4; 8 процессов ------------------------------------------
      switch Np
          case 1 % k2 
              Latt(NN) = 2;
          case 2 % k1 вниз
              Latt(NN2) = 1;
          case 3 % k1 налево
              Latt(NN3) = 1;
          case 4 % k1 вверх
              Latt(NN4) = 1;
          case 5 % d1 вниз
              Latt(NN) = 0; Latt(NN2) = 1;
          case 6 % d1 налево
              Latt(NN) = 0; Latt(NN3) = 1;
          case 7 % d1 вверх
              Latt(NN) = 0; Latt(NN4) = 1;
          case 8 % d2 направо
              Latt(NN) = 2; Latt(NN1) = 1;
          otherwise
              err = 'Error 4 class !'
              pause
      end
   
   case 5 % класс 5; 8 процессов ------------------------------------------
      switch Np
          case 1 % k2 
              Latt(NN) = 2;
          case 2 % k1 направо
              Latt(NN1) = 1;
          case 3 % k1 налево
              Latt(NN3) = 1;
          case 4 % k1 вверх
              Latt(NN4) = 1;
          case 5 % d1 направо
              Latt(NN) = 0; Latt(NN1) = 1;
          case 6 % d1 налево
              Latt(NN) = 0; Latt(NN3) = 1;
          case 7 % d1 вверх
              Latt(NN) = 0; Latt(NN4) = 1;
          case 8 % d2 вниз
              Latt(NN) = 2; Latt(NN2) = 1;
          otherwise
              err = 'Error 5 class !'
              pause
      end

   case 6 % класс 6; 7 процессов ------------------------------------------
      switch Np
          case 1 % k2 
              Latt(NN) = 2;
          case 2 % k1 направо
              Latt(NN1) = 1;
          case 3 % k1 вниз
              Latt(NN2) = 1;
          case 4 % k1 вверх
              Latt(NN4) = 1;
          case 5 % d1 направо
              Latt(NN) = 0; Latt(NN1) = 1;
          case 6 % d1 вниз
              Latt(NN) = 0; Latt(NN2) = 1;
          case 7 % d1 вверх
              Latt(NN) = 0; Latt(NN4) = 1;
          otherwise
              err = 'Error 6 class !'
              pause
     end

   case 7 % класс 7; 7 процессов ------------------------------------------
      switch Np
          case 1 % k2 
              Latt(NN) = 2;
          case 2 % k1 направо
              Latt(NN1) = 1;
          case 3 % k1 вниз
              Latt(NN2) = 1;
          case 4 % k1 налево
              Latt(NN3) = 1;
          case 5 % d1 направо
              Latt(NN) = 0; Latt(NN1) = 1;
          case 6 % d1 вниз
              Latt(NN) = 0; Latt(NN2) = 1;
          case 7 % d1 налево
              Latt(NN) = 0; Latt(NN3) = 1;
          otherwise
              err = 'Error 7 class !'
              pause
      end

   case 8 % класс 8; 7 процессов ------------------------------------------
      switch Np
          case 1 % k2 
              Latt(NN) = 2;
          case 2 % k1 вниз
              Latt(NN2) = 1;
          case 3 % k1 налево
              Latt(NN3) = 1;
          case 4 % k1 вверх
              Latt(NN4) = 1;
          case 5 % d1 вниз
              Latt(NN) = 0; Latt(NN2) = 1;
          case 6 % d1 налево
              Latt(NN) = 0; Latt(NN3) = 1;
          case 7 % d1 вверх
              Latt(NN) = 0; Latt(NN4) = 1;
          otherwise
              err = 'Error 8 class !'
              pause
      end
   
   case 9 % класс 9; 7 процессов ------------------------------------------
      switch Np
          case 1 % k2 
              Latt(NN) = 2;
          case 2 % k1 направо
              Latt(NN1) = 1;
          case 3 % k1 налево
              Latt(NN3) = 1;
          case 4 % k1 вверх
              Latt(NN4) = 1;
          case 5 % d1 направо
              Latt(NN) = 0; Latt(NN1) = 1;
          case 6 % d1 налево
              Latt(NN) = 0; Latt(NN3) = 1;
          case 7 % d1 вверх
              Latt(NN) = 0; Latt(NN4) = 1;
          otherwise
              err = 'Error 9 class !'
              pause
      end

   case 10 % класс 10; 7 процессов ----------------------------------------
      switch Np
          case 1 % k2 
              Latt(NN) = 2;
          case 2 % k1 направо
              Latt(NN1) = 1;
          case 3 % k1 вниз
              Latt(NN2) = 1;
          case 4 % d1 направо
              Latt(NN) = 0; Latt(NN1) = 1;
          case 5 % d1 вниз
              Latt(NN) = 0; Latt(NN2) = 1;
          case 6 % d2 налево
              Latt(NN) = 2; Latt(NN3) = 1;
          case 7 % d2 вверх
              Latt(NN) = 2; Latt(NN4) = 1;
          otherwise
              err = 'Error 10 class !'
              pause
      end

   case 11 % класс 11; 7 процессов ----------------------------------------
      switch Np
          case 1 % k2 
              Latt(NN) = 2;
          case 2 % k1 вниз
              Latt(NN2) = 1;
          case 3 % k1 налево
              Latt(NN3) = 1;
          case 4 % d1 вниз
              Latt(NN) = 0; Latt(NN2) = 1;
          case 5 % d1 налево
              Latt(NN) = 0; Latt(NN3) = 1;
          case 6 % d2 направо
              Latt(NN) = 2; Latt(NN1) = 1;
          case 7 % d2 вверх
              Latt(NN) = 2; Latt(NN4) = 1;
          otherwise
              err = 'Error 11 class !'
              pause
      end

   case 12 % класс 12; 7 процессов ----------------------------------------
      switch Np
          case 1 % k2 
              Latt(NN) = 2;
          case 2 % k1 налево
              Latt(NN3) = 1;
          case 3 % k1 вверх
              Latt(NN4) = 1;
          case 4 % d1 налево
              Latt(NN) = 0; Latt(NN3) = 1;
          case 5 % d1 вверх
              Latt(NN) = 0; Latt(NN4) = 1;
          case 6 % d2 направо
              Latt(NN) = 2; Latt(NN1) = 1;
          case 7 % d2 вниз
              Latt(NN) = 2; Latt(NN2) = 1;
          otherwise
              err = 'Error 12 class !'
              pause
      end

   case 13 % класс 13; 7 процессов ----------------------------------------
      switch Np
          case 1 % k2 
              Latt(NN) = 2;
          case 2 % k1 направо
              Latt(NN1) = 1;
          case 3 % k1 вверх
              Latt(NN4) = 1;
          case 4 % d1 направо
              Latt(NN) = 0; Latt(NN1) = 1;
          case 5 % d1 вверх
              Latt(NN) = 0; Latt(NN4) = 1;
          case 6 % d2 вниз
              Latt(NN) = 2; Latt(NN2) = 1;
          case 7 % d2 налево
              Latt(NN) = 2; Latt(NN3) = 1;
          otherwise
              err = 'Error 13 class !'
              pause
      end

   case 14 % класс 14; 7 процессов ----------------------------------------
      switch Np
          case 1 % k2 
              Latt(NN) = 2;
          case 2 % k1 вниз
              Latt(NN2) = 1;
          case 3 % k1 вверх
              Latt(NN4) = 1;
          case 4 % d1 вниз
              Latt(NN) = 0; Latt(NN2) = 1;
          case 5 % d1 вверх
              Latt(NN) = 0; Latt(NN4) = 1;
          case 6 % d2 направо
              Latt(NN) = 2; Latt(NN1) = 1;
          case 7 % d2 налево
              Latt(NN) = 2; Latt(NN3) = 1;
          otherwise
              err = 'Error 14 class !'
              pause
      end

   case 15 % класс 15; 7 процессов ----------------------------------------
      switch Np
          case 1 % k2 
              Latt(NN) = 2;
          case 2 % k1 направо
              Latt(NN1) = 1;
          case 3 % k1 налево
              Latt(NN3) = 1;
          case 4 % d1 направо
              Latt(NN) = 0; Latt(NN1) = 1;
          case 5 % d1 налево
              Latt(NN) = 0; Latt(NN3) = 1;
          case 6 % d2 вниз
              Latt(NN) = 2; Latt(NN2) = 1;
          case 7 % d2 вверх
              Latt(NN) = 2; Latt(NN4) = 1;
          otherwise
              err = 'Error 15 class !'
              pause
      end

   case 16 % класс 16; 5 процессов ----------------------------------------
      switch Np
          case 1 % k2 
              Latt(NN) = 2;
          case 2 % k1 направо
              Latt(NN1) = 1;
          case 3 % k1 вниз
              Latt(NN2) = 1;
          case 4 % d1 направо
              Latt(NN) = 0; Latt(NN1) = 1;
          case 5 % d1 вниз
              Latt(NN) = 0; Latt(NN2) = 1;
          otherwise
              err = 'Error 16 class !'
              pause
      end

   case 17 % класс 17; 5 процессов ----------------------------------------
      switch Np
          case 1 % k2 
              Latt(NN) = 2;
          case 2 % k1 вниз
              Latt(NN2) = 1;
          case 3 % k1 налево
              Latt(NN3) = 1;
          case 4 % d1 вниз
              Latt(NN) = 0; Latt(NN2) = 1;
          case 5 % d1 налево
              Latt(NN) = 0; Latt(NN3) = 1;
          otherwise
              err = 'Error 17 class !'
              pause
      end

   case 18 % класс 18; 5 процессов ----------------------------------------
      switch Np
          case 1 % k2 
              Latt(NN) = 2;
          case 2 % k1 налево
              Latt(NN3) = 1;
          case 3 % k1 вверх
              Latt(NN4) = 1;
          case 4 % d1 налево
              Latt(NN) = 0; Latt(NN3) = 1;
          case 5 % d1 вверх
              Latt(NN) = 0; Latt(NN4) = 1;
          otherwise
              err = 'Error 18 class !'
              pause
     end

   case 19 % класс 19; 5 процессов ----------------------------------------
      switch Np
          case 1 % k2 
              Latt(NN) = 2;
          case 2 % k1 направо
              Latt(NN1) = 1;
          case 3 % k1 вверх
              Latt(NN4) = 1;
          case 4 % d1 направо
              Latt(NN) = 0; Latt(NN1) = 1;
          case 5 % d1 вверх
              Latt(NN) = 0; Latt(NN4) = 1;
          otherwise
              err = 'Error 19 class !'
              pause
    end

   case 20 % класс 20; 5 процессов ----------------------------------------
      switch Np
          case 1 % k2 
              Latt(NN) = 2;
          case 2 % k1 вниз
              Latt(NN2) = 1;
          case 3 % k1 вверх
              Latt(NN4) = 1;
          case 4 % d1 вниз
              Latt(NN) = 0; Latt(NN2) = 1;
          case 5 % d1 вверх
              Latt(NN) = 0; Latt(NN4) = 1;
          otherwise
              err = 'Error 20 class !'
              pause
      end

   case 21 % класс 21; 6 процессов ----------------------------------------
      switch Np
          case 1 % k2 
              Latt(NN) = 2;
          case 2 % k1 направо
              Latt(NN1) = 1;
          case 3 % k1 налево
              Latt(NN3) = 1;
          case 4 % d1 направо
              Latt(NN) = 0; Latt(NN1) = 1;
          case 5 % d1 налево
              Latt(NN) = 0; Latt(NN3) = 1;
          otherwise
              err = 'Error 21 class !'
              pause
      end

   case 22 % класс 22; 6 процессов ----------------------------------------
      switch Np
          case 1 % k2 
              Latt(NN) = 2;
          case 2 % k1 направо
              Latt(NN1) = 1;
          case 3 % k1 вниз
              Latt(NN2) = 1;
          case 4 % d1 направо
              Latt(NN) = 0; Latt(NN1) = 1;
          case 5 % d1 вниз
              Latt(NN) = 0; Latt(NN2) = 1;
          case 6 % d2 вверх
              Latt(NN) = 2; Latt(NN4) = 1;
          otherwise
              err = 'Error 22 class !'
              pause
      end

   case 23 % класс 23; 6 процессов ----------------------------------------
      switch Np
          case 1 % k2 
              Latt(NN) = 2;
          case 2 % k1 вниз
              Latt(NN2) = 1;
          case 3 % k1 налево
              Latt(NN3) = 1;
          case 4 % d1 вниз
              Latt(NN) = 0; Latt(NN2) = 1;
          case 5 % d1 налево
              Latt(NN) = 0; Latt(NN3) = 1;
          case 6 % d2 направо
              Latt(NN) = 2; Latt(NN1) = 1;
          otherwise
              err = 'Error 23 class !'
              pause
      end

   case 24 % класс 24; 6 процессов ----------------------------------------
      switch Np
          case 1 % k2 
              Latt(NN) = 2;
          case 2 % k1 налево
              Latt(NN3) = 1;
          case 3 % k1 вверх
              Latt(NN4) = 1;
          case 4 % d1 налево
              Latt(NN) = 0; Latt(NN3) = 1;
          case 5 % d1 вверх
              Latt(NN) = 0; Latt(NN4) = 1;
          case 6 % d2 вниз
              Latt(NN) = 2; Latt(NN2) = 1;
          otherwise
              err = 'Error 24 class !'
              pause
      end

   case 25 % класс 25; 6 процессов ----------------------------------------
      switch Np
          case 1 % k2 
              Latt(NN) = 2;
          case 2 % k1 направо
              Latt(NN1) = 1;
          case 3 % k1 вверх
              Latt(NN4) = 1;
          case 4 % d1 направо
              Latt(NN) = 0; Latt(NN1) = 1;
          case 5 % d1 вверх
              Latt(NN) = 0; Latt(NN4) = 1;
          case 6 % d2 налево
              Latt(NN) = 2; Latt(NN3) = 1;
          otherwise
              err = 'Error 25 class !'
              pause
      end

   case 26 % класс 26; 6 процессов ----------------------------------------
      switch Np
          case 1 % k2 
              Latt(NN) = 2;
          case 2 % k1 вниз
              Latt(NN2) = 1;
          case 3 % k1 вверх
              Latt(NN4) = 1;
          case 4 % d1 вниз
              Latt(NN) = 0; Latt(NN2) = 1;
          case 5 % d1 вверх
              Latt(NN) = 0; Latt(NN4) = 1;
          case 6 % d2 направо
              Latt(NN) = 2; Latt(NN1) = 1;
          otherwise
              err = 'Error 26 class !'
              pause
     end

   case 27 % класс 27; 6 процессов ----------------------------------------
      switch Np
          case 1 % k2 
              Latt(NN) = 2;
          case 2 % k1 направо
              Latt(NN1) = 1;
          case 3 % k1 налево
              Latt(NN3) = 1;
          case 4 % d1 направо
              Latt(NN) = 0; Latt(NN1) = 1;
          case 5 % d1 налево
              Latt(NN) = 0; Latt(NN3) = 1;
          case 6 % d2 вниз
              Latt(NN) = 2; Latt(NN2) = 1;
          otherwise
              err = 'Error 27 class !'
              pause
      end

   case 28 % класс 28; 6 процессов ----------------------------------------
      switch Np
          case 1 % k2 
              Latt(NN) = 2;
          case 2 % k1 направо
              Latt(NN1) = 1;
          case 3 % k1 вниз
              Latt(NN2) = 1;
          case 4 % d1 направо
              Latt(NN) = 0; Latt(NN1) = 1;
          case 5 % d1 вниз
              Latt(NN) = 0; Latt(NN2) = 1;
          case 6 % d2 налево
              Latt(NN) = 2; Latt(NN3) = 1;
          otherwise
              err = 'Error 28 class !'
              pause
      end

   case 29 % класс 29; 6 процессов ----------------------------------------
      switch Np
          case 1 % k2 
              Latt(NN) = 2;
          case 2 % k1 вниз
              Latt(NN2) = 1;
          case 3 % k1 налево
              Latt(NN3) = 1;
          case 4 % d1 вниз
              Latt(NN) = 0; Latt(NN2) = 1;
          case 5 % d1 налево
              Latt(NN) = 0; Latt(NN3) = 1;
          case 6 % d2 вверх
              Latt(NN) = 2; Latt(NN4) = 1;
          otherwise
              err = 'Error 29 class !'
              pause
      end

   case 30 % класс 30; 6 процессов ----------------------------------------
      switch Np
          case 1 % k2 
              Latt(NN) = 2;
          case 2 % k1 налево
              Latt(NN3) = 1;
          case 3 % k1 вверх
              Latt(NN4) = 1;
          case 4 % d1 налево
              Latt(NN) = 0; Latt(NN3) = 1;
          case 5 % d1 вверх
              Latt(NN) = 0; Latt(NN4) = 1;
          case 6 % d2 направо
              Latt(NN) = 2; Latt(NN1) = 1;
          otherwise
              err = 'Error 30 class !'
              pause
      end

   case 31 % класс 31; 6 процессов ----------------------------------------
      switch Np
          case 1 % k2 
              Latt(NN) = 2;
          case 2 % k1 направо
              Latt(NN1) = 1;
          case 3 % k1 вверх
              Latt(NN4) = 1;
          case 4 % d1 направо
              Latt(NN) = 0; Latt(NN1) = 1;
          case 5 % d1 вверх
              Latt(NN) = 0; Latt(NN4) = 1;
          case 6 % d2 вниз
              Latt(NN) = 2; Latt(NN2) = 1;
          otherwise
              err = 'Error 31 class !'
              pause
      end

   case 32 % класс 32; 6 процессов ----------------------------------------
      switch Np
          case 1 % k2 
              Latt(NN) = 2;
          case 2 % k1 вниз
              Latt(NN2) = 1;
          case 3 % k1 вверх
              Latt(NN4) = 1;
          case 4 % d1 вниз
              Latt(NN) = 0; Latt(NN2) = 1;
          case 5 % d1 вверх
              Latt(NN) = 0; Latt(NN4) = 1;
          case 6 % d2 налево
              Latt(NN) = 2; Latt(NN3) = 1;
          otherwise
              err = 'Error 32 class !'
              pause
      end

   case 33 % класс 33; 6 процессов ----------------------------------------
      switch Np
          case 1 % k2 
              Latt(NN) = 2;
          case 2 % k1 направо
              Latt(NN1) = 1;
          case 3 % k1 налево
              Latt(NN3) = 1;
          case 4 % d1 направо
              Latt(NN) = 0; Latt(NN1) = 1;
          case 5 % d1 налево
              Latt(NN) = 0; Latt(NN3) = 1;
          case 6 % d2 вверх
              Latt(NN) = 2; Latt(NN4) = 1;
          otherwise
              err = 'Error 33 class !'
              pause
      end

   case 34 % класс 34; 6 процессов ----------------------------------------
      switch Np
          case 1 % k2 
              Latt(NN) = 2;
          case 2 % k1 вниз
              Latt(NN2) = 1;
          case 3 % d1 вниз
              Latt(NN) = 0; Latt(NN2) = 1;
          case 4 % d2 направо
              Latt(NN) = 2; Latt(NN1) = 1;
          case 5 % d2 налево
              Latt(NN) = 2; Latt(NN3) = 1;
          case 6 % d2 вверх
              Latt(NN) = 2; Latt(NN4) = 1;
          otherwise
              err = 'Error 34 class !'
              pause
      end

   case 35 % класс 35; 6 процессов ----------------------------------------
      switch Np
          case 1 % k2 
              Latt(NN) = 2;
          case 2 % k1 налево
              Latt(NN3) = 1;
          case 3 % d1 налево
              Latt(NN) = 0; Latt(NN3) = 1;
          case 4 % d2 направо
              Latt(NN) = 2; Latt(NN1) = 1;
          case 5 % d2 вниз
              Latt(NN) = 2; Latt(NN2) = 1;
          case 6 % d2 вверх
              Latt(NN) = 2; Latt(NN4) = 1;
          otherwise
              err = 'Error 35 class !'
              pause
      end

   case 36 % класс 36; 6 процессов ----------------------------------------
      switch Np
          case 1 % k2 
              Latt(NN) = 2;
          case 2 % k1 вверх
              Latt(NN4) = 1;
          case 3 % d1 вверх
              Latt(NN) = 0; Latt(NN4) = 1;
          case 4 % d2 направо
              Latt(NN) = 2; Latt(NN1) = 1;
          case 5 % d2 вниз
              Latt(NN) = 2; Latt(NN2) = 1;
          case 6 % d2 налево
              Latt(NN) = 2; Latt(NN3) = 1;
          otherwise
              err = 'Error 36 class !'
              pause
      end

   case 37 % класс 37; 6 процессов ----------------------------------------
      switch Np
          case 1 % k2 
              Latt(NN) = 2;
          case 2 % k1 направо
              Latt(NN1) = 1;
          case 3 % d1 направо
              Latt(NN) = 0; Latt(NN1) = 1;
          case 4 % d2 вниз
              Latt(NN) = 2; Latt(NN2) = 1;
          case 5 % d2 налево
              Latt(NN) = 2; Latt(NN3) = 1;
          case 6 % d2 вверх
              Latt(NN) = 2; Latt(NN4) = 1;
          otherwise
              err = 'Error 37 class !'
              pause
     end

   case 38 % класс 38; 3 процесса -----------------------------------------
      switch Np
          case 1 % k2 
              Latt(NN) = 2;
          case 2 % k1 вниз
              Latt(NN2) = 1;
          case 3 % d1 вниз
              Latt(NN) = 0; Latt(NN2) = 1;
          otherwise
              err = 'Error 38 class !'
              pause
      end

   case 39 % класс 39; 3 процесса -----------------------------------------
      switch Np
          case 1 % k2 
              Latt(NN) = 2;
          case 2 % k1 налево
              Latt(NN3) = 1;
          case 3 % d1 налево
              Latt(NN) = 0; Latt(NN3) = 1;
          otherwise
              err = 'Error 39 class !'
              pause
      end

   case 40 % класс 40; 3 процесса -----------------------------------------
      switch Np
          case 1 % k2 
              Latt(NN) = 2;
          case 2 % k1 вверх
              Latt(NN4) = 1;
          case 3 % d1 вверх
              Latt(NN) = 0; Latt(NN4) = 1;
          otherwise
              err = 'Error 40 class !'
              pause
      end

   case 41 % класс 41; 3 процесса -----------------------------------------
      switch Np
          case 1 % k2 
              Latt(NN) = 2;
          case 2 % k1 направо
              Latt(NN1) = 1;
          case 3 % d1 направо
              Latt(NN) = 0; Latt(NN1) = 1;
          otherwise
              err = 'Error 41 class !'
              pause
      end

   case 42 % класс 42; 5 процессов ----------------------------------------
      switch Np
          case 1 % k2 
              Latt(NN) = 2;
          case 2 % k1 вниз
              Latt(NN2) = 1;
          case 3 % d1 вниз
              Latt(NN) = 0; Latt(NN2) = 1;
          case 4 % d2 направо
              Latt(NN) = 2; Latt(NN1) = 1;
          case 5 % d2 вверх
              Latt(NN) = 2; Latt(NN4) = 1;
          otherwise
              err = 'Error 42 class !'
              pause
      end

   case 43 % класс 43; 5 процессов ----------------------------------------
      switch Np
          case 1 % k2 
              Latt(NN) = 2;
          case 2 % k1 налево
              Latt(NN3) = 1;
          case 3 % d1 налево
              Latt(NN) = 0; Latt(NN3) = 1;
          case 4 % d2 направо
              Latt(NN) = 2; Latt(NN1) = 1;
          case 5 % d2 вниз
              Latt(NN) = 2; Latt(NN2) = 1;
          otherwise
              err = 'Error 43 class !'
              pause
      end

   case 44 % класс 44; 5 процессов ----------------------------------------
      switch Np
          case 1 % k2 
              Latt(NN) = 2;
          case 2 % k1 вверх
              Latt(NN4) = 1;
          case 3 % d1 вверх
              Latt(NN) = 0; Latt(NN4) = 1;
          case 4 % d2 вниз
              Latt(NN) = 2; Latt(NN2) = 1;
          case 5 % d2 налево
              Latt(NN) = 2; Latt(NN3) = 1;
          otherwise
              err = 'Error 44 class !'
              pause
      end

   case 45 % класс 45; 5 процессов ----------------------------------------
      switch Np
          case 1 % k2 
              Latt(NN) = 2;
          case 2 % k1 направо
              Latt(NN1) = 1;
          case 3 % d1 направо
              Latt(NN) = 0; Latt(NN1) = 1;
          case 4 % d2 вниз
              Latt(NN) = 2; Latt(NN2) = 1;
          case 5 % d2 налево
              Latt(NN) = 2; Latt(NN3) = 1;
          otherwise
              err = 'Error 45 class !'
              pause
      end

   case 46 % класс 46; 5 процессов ----------------------------------------
      switch Np
          case 1 % k2 
              Latt(NN) = 2;
          case 2 % k1 вниз
              Latt(NN2) = 1;
          case 3 % d1 вниз
              Latt(NN) = 0; Latt(NN2) = 1;
          case 4 % d2 направо
              Latt(NN) = 2; Latt(NN1) = 1;
          case 5 % d2 налево
              Latt(NN) = 2; Latt(NN3) = 1;
          otherwise
              err = 'Error 46 class !'
              pause
     end

   case 47 % класс 47; 5 процессов ----------------------------------------
      switch Np
          case 1 % k2 
              Latt(NN) = 2;
          case 2 % k1 налево
              Latt(NN3) = 1;
          case 3 % d1 налево
              Latt(NN) = 0; Latt(NN3) = 1;
          case 4 % d2 вниз
              Latt(NN) = 2; Latt(NN2) = 1;
          case 5 % d2 вверх
              Latt(NN) = 2; Latt(NN4) = 1;
          otherwise
              err = 'Error 47 class !'
              pause
      end

   case 48 % класс 48; 5 процессов ----------------------------------------
      switch Np
          case 1 % k2 
              Latt(NN) = 2;
          case 2 % k1 вверх
              Latt(NN4) = 1;
          case 3 % d1 вверх
              Latt(NN) = 0; Latt(NN4) = 1;
          case 4 % d2 направо
              Latt(NN) = 2; Latt(NN1) = 1;
          case 5 % d2 налево
              Latt(NN) = 2; Latt(NN3) = 1;
          otherwise
              err = 'Error 48 class !'
              pause
      end

   case 49 % класс 49; 5 процессов ----------------------------------------
      switch Np
          case 1 % k2 
              Latt(NN) = 2;
          case 2 % k1 направо
              Latt(NN1) = 1;
          case 3 % d1 направо
              Latt(NN) = 0; Latt(NN1) = 1;
          case 4 % d2 вниз
              Latt(NN) = 2; Latt(NN2) = 1;
          case 5 % d2 вверх
              Latt(NN) = 2; Latt(NN4) = 1;
          otherwise
              err = 'Error 49 class !'
              pause
      end

   case 50 % класс 50; 5 процессов ----------------------------------------
      switch Np
          case 1 % k2 
              Latt(NN) = 2;
          case 2 % k1 вниз
              Latt(NN2) = 1;
          case 3 % d1 вниз
              Latt(NN) = 0; Latt(NN2) = 1;
          case 4 % d2 налево
              Latt(NN) = 2; Latt(NN3) = 1;
          case 5 % d2 вверх
              Latt(NN) = 2; Latt(NN4) = 1;
          otherwise
              err = 'Error 50 class !'
              pause
      end

   case 51 % класс 51; 5 процессов ----------------------------------------
      switch Np
          case 1 % k2 
              Latt(NN) = 2;
          case 2 % k1 налево
              Latt(NN3) = 1;
          case 3 % d1 налево
              Latt(NN) = 0; Latt(NN3) = 1;
          case 4 % d2 направо
              Latt(NN) = 2; Latt(NN1) = 1;
          case 5 % d2 вверх
              Latt(NN) = 2; Latt(NN4) = 1;
          otherwise
              err = 'Error 51 class !'
              pause
     end

   case 52 % класс 52; 5 процессов ----------------------------------------
      switch Np
          case 1 % k2 
              Latt(NN) = 2;
          case 2 % k1 вверх
              Latt(NN4) = 1;
          case 3 % d1 вверх
              Latt(NN) = 0; Latt(NN4) = 1;
          case 4 % d2 направо
              Latt(NN) = 2; Latt(NN1) = 1;
          case 5 % d2 вниз
              Latt(NN) = 2; Latt(NN2) = 1;
          otherwise
              err = 'Error 52 class !'
              pause
      end

   case 53 % класс 53; 5 процессов ----------------------------------------
      switch Np
          case 1 % k2 
              Latt(NN) = 2;
          case 2 % k1 направо
              Latt(NN1) = 1;
          case 3 % d1 направо
              Latt(NN) = 0; Latt(NN1) = 1;
          case 4 % d2 налево
              Latt(NN) = 2; Latt(NN3) = 1;
          case 5 % d2 вверх
              Latt(NN) = 2; Latt(NN4) = 1;
          otherwise
              err = 'Error 530 class !'
              pause
     end

   case 54 % класс 54; 4 процесса -----------------------------------------
      switch Np
          case 1 % k2 
              Latt(NN) = 2;
          case 2 % k1 вниз
              Latt(NN2) = 1;
          case 3 % d1 вниз
              Latt(NN) = 0; Latt(NN2) = 1;
          case 4 % d2 направо
              Latt(NN) = 2; Latt(NN1) = 1;
          otherwise
              err = 'Error 54 class !'
              pause
      end

   case 55 % класс 55; 4 процесса -----------------------------------------
      switch Np
          case 1 % k2 
              Latt(NN) = 2;
          case 2 % k1 налево
              Latt(NN3) = 1;
          case 3 % d1 налево
              Latt(NN) = 0; Latt(NN3) = 1;
          case 4 % d2 вниз
              Latt(NN) = 2; Latt(NN2) = 1;
          otherwise
              err = 'Error 55 class !'
              pause
      end

   case 56 % класс 56; 4 процесса -----------------------------------------
      switch Np
          case 1 % k2 
              Latt(NN) = 2;
          case 2 % k1 вверх
              Latt(NN4) = 1;
          case 3 % d1 вверх
              Latt(NN) = 0; Latt(NN4) = 1;
          case 4 % d2 налево
              Latt(NN) = 2; Latt(NN3) = 1;
          otherwise
              err = 'Error 56 class !'
              pause
      end

   case 57 % класс 57; 4 процесса -----------------------------------------
      switch Np
          case 1 % k2 
              Latt(NN) = 2;
          case 2 % k1 направо
              Latt(NN1) = 1;
          case 3 % d1 направо
              Latt(NN) = 0; Latt(NN1) = 1;
          case 4 % d2 вниз
              Latt(NN) = 2; Latt(NN2) = 1;
          otherwise
              err = 'Error 57 class !'
              pause
      end

   case 58 % класс 58; 4 процесса -----------------------------------------
      switch Np
          case 1 % k2 
              Latt(NN) = 2;
          case 2 % k1 вниз
              Latt(NN2) = 1;
          case 3 % d1 вниз
              Latt(NN) = 0; Latt(NN2) = 1;
          case 4 % d2 налево
              Latt(NN) = 2; Latt(NN3) = 1;
          otherwise
              err = 'Error 58 class !'
              pause
      end

   case 59 % класс 59; 4 процесса -----------------------------------------
      switch Np
          case 1 % k2 
              Latt(NN) = 2;
          case 2 % k1 налево
              Latt(NN3) = 1;
          case 3 % d1 налево
              Latt(NN) = 0; Latt(NN3) = 1;
          case 4 % d2 вверх
              Latt(NN) = 2; Latt(NN4) = 1;
          otherwise
              err = 'Error 59 class !'
              pause
     end

   case 60 % класс 60; 4 процесса -----------------------------------------
      switch Np
          case 1 % k2 
              Latt(NN) = 2;
          case 2 % k1 вверх
              Latt(NN4) = 1;
          case 3 % d1 вверх
              Latt(NN) = 0; Latt(NN4) = 1;
          case 4 % d2 направо
              Latt(NN) = 2; Latt(NN1) = 1;
          otherwise
              err = 'Error 60 class !'
              pause
      end

   case 61 % класс 61; 4 процесса -----------------------------------------
      switch Np
          case 1 % k2 
              Latt(NN) = 2;
          case 2 % k1 направо
              Latt(NN1) = 1;
          case 3 % d1 направо
              Latt(NN) = 0; Latt(NN1) = 1;
          case 4 % d2 вверх
              Latt(NN) = 2; Latt(NN4) = 1;
          otherwise
              err = 'Error 61 class !'
              pause
      end

   case 62 % класс 62; 4 процесса -----------------------------------------
      switch Np
          case 1 % k2 
              Latt(NN) = 2;
          case 2 % k1 вниз
              Latt(NN2) = 1;
          case 3 % d1 вниз
              Latt(NN) = 0; Latt(NN2) = 1;
          case 4 % d2 вверх
              Latt(NN) = 2; Latt(NN4) = 1;
          otherwise
              err = 'Error 62 class !'
              pause
      end

   case 63 % класс 63; 4 процесса -----------------------------------------
      switch Np
          case 1 % k2 
              Latt(NN) = 2;
          case 2 % k1 налево
              Latt(NN3) = 1;
          case 3 % d1 налево
              Latt(NN) = 0; Latt(NN3) = 1;
          case 4 % d2 направо
              Latt(NN) = 2; Latt(NN1) = 1;
          otherwise
              err = 'Error 63 class !'
              pause
      end

   case 64 % класс 64; 4 процесса -----------------------------------------
      switch Np
          case 1 % k2 
              Latt(NN) = 2;
          case 2 % k1 вверх
              Latt(NN4) = 1;
          case 3 % d1 вверх
              Latt(NN) = 0; Latt(NN4) = 1;
          case 4 % d2 вниз
              Latt(NN) = 2; Latt(NN2) = 1;
          otherwise
              err = 'Error 64 class !'
              pause
      end

   case 65 % класс 65; 4 процесса -----------------------------------------
      switch Np
          case 1 % k2 
              Latt(NN) = 2;
          case 2 % k1 направо
              Latt(NN1) = 1;
          case 3 % d1 направо
              Latt(NN) = 0; Latt(NN1) = 1;
          case 4 % d2 налево
              Latt(NN) = 2; Latt(NN3) = 1;
          otherwise
              err = 'Error 65 class !'
              pause
     end

   case 66 % класс 66; 1 процесс ------------------------------------------
      switch Np
          case 1 % k2 
              Latt(NN) = 2;
          otherwise
              err = 'Error 66 class !'
              pause
     end

   case 67 % класс 67; 5 процессов ----------------------------------------
      switch Np
          case 1 % k2 
              Latt(NN) = 2;
          case 2 % d2 направо
              Latt(NN) = 2; Latt(NN1) = 1;
          case 3 % d2 вниз
              Latt(NN) = 2; Latt(NN2) = 1;
          case 4 % d2 налево
              Latt(NN) = 2; Latt(NN3) = 1;
          case 5 % d2 вверх
              Latt(NN) = 2; Latt(NN4) = 1;
          otherwise
              err = 'Error 67 class !'
              pause
      end

   case 68 % класс 68; 2 процесса -----------------------------------------
      switch Np
          case 1 % k2 
              Latt(NN) = 2;
          case 2 % d2 направо
              Latt(NN) = 2; Latt(NN1) = 1;
          otherwise
              err = 'Error 68 class !'
              pause
      end

   case 69 % класс 69; 2 процесса -----------------------------------------
      switch Np
          case 1 % k2 
              Latt(NN) = 2;
          case 2 % d2 вверх
              Latt(NN) = 2; Latt(NN4) = 1;
          otherwise
              err = 'Error 69 class !'
              pause
      end

   case 70 % класс 70; 2 процесса -----------------------------------------
      switch Np
          case 1 % k2 
              Latt(NN) = 2;
          case 2 % d2 налево
              Latt(NN) = 2; Latt(NN3) = 1;
          otherwise
              err = 'Error 70 class !'
              pause
      end

   case 71 % класс 71; 2 процесса -----------------------------------------
      switch Np
          case 1 % k2 
              Latt(NN) = 2;
          case 2 % d2 вниз
              Latt(NN) = 2; Latt(NN2) = 1;
          otherwise
              err = 'Error 71 class !'
              pause
      end

   case 72 % класс 72; 3 процесса -----------------------------------------
      switch Np
          case 1 % k2 
              Latt(NN) = 2;
          case 2 % d2 направо
              Latt(NN) = 2; Latt(NN1) = 1;
          case 3 % d2 вниз
              Latt(NN) = 2; Latt(NN2) = 1;
          otherwise
              err = 'Error 72 class !'
              pause
      end

   case 73 % класс 73; 3 процесса -----------------------------------------
      switch Np
          case 1 % k2 
              Latt(NN) = 2;
          case 2 % d2 направо
              Latt(NN) = 2; Latt(NN1) = 1;
          case 3 % d2 вверх
              Latt(NN) = 2; Latt(NN4) = 1;
          otherwise
              err = 'Error 73 class !'
              pause
      end

   case 74 % класс 74; 3 процесса -----------------------------------------
      switch Np
          case 1 % k2 
              Latt(NN) = 2;
          case 2 % d2 налево
              Latt(NN) = 2; Latt(NN3) = 1;
          case 3 % d2 вверх
              Latt(NN) = 2; Latt(NN4) = 1;
          otherwise
              err = 'Error 74 class !'
              pause
      end

   case 75 % класс 75; 3 процесса -----------------------------------------
      switch Np
          case 1 % k2 
              Latt(NN) = 2;
          case 2 % d2 вниз
              Latt(NN) = 2; Latt(NN2) = 1;
          case 3 % d2 налево
              Latt(NN) = 2; Latt(NN3) = 1;
          otherwise
              err = 'Error 75 class !'
              pause
      end

   case 76 % класс 76; 3 процесса -----------------------------------------
      switch Np
          case 1 % k2 
              Latt(NN) = 2;
          case 2 % d2 вниз
              Latt(NN) = 2; Latt(NN2) = 1;
          case 3 % d2 вверх
              Latt(NN) = 2; Latt(NN4) = 1;
          otherwise
              err = 'Error 76 class !'
              pause
      end

   case 77 % класс 77; 3 процесса -----------------------------------------
      switch Np
          case 1 % k2 
              Latt(NN) = 2;
          case 2 % d2 направо
              Latt(NN) = 2; Latt(NN1) = 1;
          case 3 % d2 налево
              Latt(NN) = 2; Latt(NN3) = 1;
          otherwise
              err = 'Error 77 class !'
              pause
      end

   case 78 % класс 78; 4 процесса -----------------------------------------
      switch Np
          case 1 % k2 
              Latt(NN) = 2;
          case 2 % d2 вниз
              Latt(NN) = 2; Latt(NN2) = 1;
          case 3 % d2 налево
              Latt(NN) = 2; Latt(NN3) = 1;
          case 4 % d2 вверх
              Latt(NN) = 2; Latt(NN4) = 1;
          otherwise
              err = 'Error 78 class !'
              pause
      end

   case 79 % класс 79; 4 процесса -----------------------------------------
      switch Np
          case 1 % k2 
              Latt(NN) = 2;
          case 2 % d2 направо
              Latt(NN) = 2; Latt(NN1) = 1;
          case 3 % d2 вниз
              Latt(NN) = 2; Latt(NN2) = 1;
          case 4 % d2 налево
              Latt(NN) = 2; Latt(NN3) = 1;
          otherwise
              err = 'Error 79 class !'
              pause
      end

   case 80 % класс 80; 4 процесса -----------------------------------------
      switch Np
          case 1 % k2 
              Latt(NN) = 2;
          case 2 % d2 направо
              Latt(NN) = 2; Latt(NN1) = 1;
          case 3 % d2 вниз
              Latt(NN) = 2; Latt(NN2) = 1;
          case 4 % d2 вверх
              Latt(NN) = 2; Latt(NN4) = 1;
          otherwise
              err = 'Error 80 class !'
              pause
      end

   case 81 % класс 81; 4 процесса -----------------------------------------
      switch Np
          case 1 % k2 
              Latt(NN) = 2;
          case 2 % d2 направо
              Latt(NN) = 2; Latt(NN1) = 1;
          case 3 % d2 налево
              Latt(NN) = 2; Latt(NN3) = 1;
          case 4 % d2 вверх
              Latt(NN) = 2; Latt(NN4) = 1;
          otherwise
              err = 'Error 81 class !'
              pause
      end

   case 82 % класс 82; 1 процесс ------------------------------------------
      switch Np
          case 1 % k3 
              Latt(NN) = 0;
          otherwise
              err = 'Error 82 class !'
              pause
      end

      case 83 % класс 83; 2 процессa --------------------------------------
      switch Np
          case 1 % k3 
              Latt(NN) = 0;
          case 2 % d3 в свободный узел
              if (Latt(NN1) == 0)
                  Latt(NN) = 0; Latt(NN1) = 2;                  
              end
              if (Latt(NN2) == 0)
                  Latt(NN) = 0; Latt(NN2) = 2;                  
              end
              if (Latt(NN3) == 0)
                  Latt(NN) = 0; Latt(NN3) = 2;                  
              end
              if (Latt(NN4) == 0)
                  Latt(NN) = 0; Latt(NN4) = 2;                  
              end
          otherwise
              err = 'Error 83 class !'
              pause
      end

      case 84 % класс 84; 3 процессa --------------------------------------
      switch Np
          case 1 % k3 
              Latt(NN) = 0;
          case 2 % d3 в первый свободный узел
              for j = 1 : 4
                  if (Latt(Nei(j,NN)) == 0)
                      Latt(NN) = 0; Latt(Nei(j,NN)) = 2;  
                      break
                  end               
              end
           case 3 % d3 во второй свободный узел
              kk = 0;
              for j = 1 : 4                  
                  if (Latt(Nei(j,NN)) == 0)
                      kk = kk + 1;
                      if (kk == 2)
                          Latt(NN) = 0; Latt(Nei(j,NN)) = 2;  
                          break
                      end
                  end
              end
          otherwise
              err = 'Error 43 class !'
              pause
      end

      case 85 % класс 85; 4 процессa --------------------------------------
      switch Np
          case 1 % k3 
              Latt(NN) = 0;
          case 2 % d3 в первый свободный узел
              for j = 1 : 4
                  if (Latt(Nei(j,NN)) == 0)
                      Latt(NN) = 0; Latt(Nei(j,NN)) = 2;  
                      break
                  end               
              end
          case 3 % d3 во второй свободный узел
              kk = 0;
              for j = 1 : 4                  
                  if (Latt(Nei(j,NN)) == 0)
                      kk = kk + 1;
                      if (kk == 2)
                          Latt(NN) = 0; Latt(Nei(j,NN)) = 2;  
                          break
                      end
                  end
              end
          case 4 % d3 в третий свободный узел
              kk = 0;
              for j = 1 : 4                  
                  Latt(Nei(j,NN))
                  if (Latt(Nei(j,NN)) == 0)
                      kk = kk + 1;
                      if (kk == 3)
                          Latt(NN) = 0; Latt(Nei(j,NN)) = 2;  
                          break
                      end
                  end
              end          
          otherwise
             err = 'Error 86 class !'
             pause
      end

      case 86 % класс 86; 5 процессов -------------------------------------
      switch Np
          case 1 % k3 
              Latt(NN) = 0;
          case 2 % d3 в первый свободный узел
              for j = 1 : 4
                  if (Latt(Nei(j,NN)) == 0)
                      Latt(NN) = 0; Latt(Nei(j,NN)) = 2;  
                      break
                  end               
              end
          case 3 % d3 во второй свободный узел
              kk = 0;
              for j = 1 : 4                  
                  if (Latt(Nei(j,NN)) == 0)
                      kk = kk + 1;
                      if (kk == 2)
                          Latt(NN) = 0; Latt(Nei(j,NN)) = 2;  
                          break
                      end
                  end
              end
          case 4 % d3 в третий свободный узел
              kk = 0;
              for j = 1 : 4                  
                  if (Latt(Nei(j,NN)) == 0)
                      kk = kk + 1;
                      if (kk == 3)
                          Latt(NN) = 0; Latt(Nei(j,NN)) = 2;  
                          break
                      end
                  end
              end          
         case 5 % d3 в четвёртый свободный узел
              kk = 0;
              for j = 1 : 4                  
                  if (Latt(Nei(j,NN)) == 0)
                      kk = kk + 1;
                      if (kk == 4)
                          Latt(NN) = 0; Latt(Nei(j,NN)) = 2;  
                          break
                      end
                  end
              end          
          otherwise
              err = 'Error 86 class !'
              pause
      end

end

%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
function local_recalc(i)
%==========================================================================
global Latt Nei Latt_cl Latt_cl_n
global class_MC numb_class_MC
%**************************************************************************
Nc = Latt_cl(i);       % номер старого класса узла i
Ns = Latt_cl_n(i);     % номер узла i в списке старого класса
%--------------------------------------------------------------------------
if (Nc > 0) % если узел был в некотором классе
    % a = class_MC(Nc)
    %----------------------------------------------------------------------
    % на место i-го элемента ставим последний элемент класса, 
    % меняем таблицу Latt_cl_n для передвинутого узла
    class_MC(Nc).list(Ns) = class_MC(Nc).list(class_MC(Nc).numb_list);
    Latt_cl_n(class_MC(Nc).list(Ns)) = Ns;
    %----------------------------------------------------------------------
    % обнуляем последний элемент класса
    class_MC(Nc).list(class_MC(Nc).numb_list) = 0;
    %----------------------------------------------------------------------
    % уменьшаем число элементов в классе на 1
    class_MC(Nc).numb_list = class_MC(Nc).numb_list - 1;
    % a = class_MC(Nc)
end
%--------------------------------------------------------------------------
Latt_cl(i)   = 0;
Latt_cl_n(i) = 0;
% анализируем новое состояние и определяем новый класс
if (Latt(i) == 1)
    a = zeros(1, 1, 'int32'); % кодовое число класса
    % вычисляем кодовое число конфигурации соседей
    a = Latt(Nei(1,i))*10000 + ...
        Latt(Nei(2,i))*1000 + ...
        Latt(Nei(3,i))*100 + ...
        Latt(Nei(4,i))*10 + 1;
    % ищем нужный класс
    for j = 1 : numb_class_MC
        if (a == class_MC(j).code)
            class_MC(j).numb_list = class_MC(j).numb_list + 1; 
            class_MC(j).list(class_MC(j).numb_list) = i;
            Latt_cl(i) = j;
            Latt_cl_n(i) = class_MC(j).numb_list;
            break
        end
    end
end
if (Latt(i) == 2)
    kk = 0;
    for j = 1 : 4
        if(Latt(Nei(j,i)) == 0)
            kk = kk + 1;
        end
    end
    j = 82;
    if (kk == 1) 
        j = 83; 
    end
    if (kk == 2) 
        j = 84; 
    end
    if (kk == 3) 
        j = 85; 
    end
    if (kk == 4) 
        j = 86; 
    end

    class_MC(j).numb_list = class_MC(j).numb_list + 1; 
    class_MC(j).list(class_MC(j).numb_list) = i;
    Latt_cl(i)   = j;
    Latt_cl_n(i) = class_MC(j).numb_list;
end
% a = class_MC(j)

%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
function plot_MC
%==========================================================================
global t0 t1 t_end dt_fig res
%**************************************************************************
res
figure
plot( res(:,1), res(:,2), 'LineWidth', 2, 'Color', 'r' ); hold on;
plot( res(:,1), res(:,3), 'LineWidth', 2, 'Color', 'b' ); hold on;
plot( res(:,1), res(:,4), 'LineWidth', 2, 'Color', 'k' ); hold on;
legend ('x', 'y', 'z' )
xlim([t0 t_end]);
ylim([0 1]);
xlabel('time', 'FontSize', 14); ylabel('\theta', 'FontSize', 14); hold on;
title('SIRS', 'FontSize', 14); hold on; grid on; 
hold on;

%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
function my_closereq(src,evnt)
%==========================================================================
global h_fig1 FigClosed
%**************************************************************************
selection = questdlg('Close This Figure?', '','Yes', 'No', 'Yes'); 
switch selection, ... 
   case 'Yes', ...
      FigClosed = 1;
   case 'No'
   return 
end
%==========================================================================
