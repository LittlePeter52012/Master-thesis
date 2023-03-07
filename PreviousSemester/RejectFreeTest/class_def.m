function class_def
% Описание классов для квадратной решётки при трёх состояниях узлов
%==========================================================================

% Global Parameters
%**************************************************************************
global k1 k2 k3 d1 d2
global Nx Ny N
global Latt Nei
global class_MC number_class_MC

%**************************************************************************
List = zeros(N, 1, 'int32')
% class_MC(1,66) = struct('number', 0.0, ...
%                         'rates', [0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0], ...
%                         'sum_rates', 0.0, ...
%                         'numb_rates', 0.0, ...
%                         'list', List, ... );
%                         'list_number', ..., 0,

%**************************************************************************
class_MC(1).number          = 00001;
class_MC(1).rate            = [k2 ...
                               k2+k1 k2+2*k1 k2+3*k1 k2+4*k1 ...
                               k2+4*k1+d1 k2+4*k1+2*d1 k2+4*k1+3*d1 k2+4*k1+4*d1];
class_MC(1).numb_rates      = 9;
class_MC(1).sum_rates       = class_MC(1).rates(class_MC(1).numb_rates);
class_MC(1).rates           = class_MC(1).rates / class_MC(1).sum_rates;
class_MC(1).list            = List;
class_MC(1).list_number     = 0;
% a = class_MC(1).rates

%--------------------------------------------------------------------------
class_MC(2).number          = 00201;
class_MC(2).rate            = [k2...
                               k2+k1 k2+2*k2 k2+3*k1...
                               k2+3*k1+d1 k2+3*k1+2*d1 k2+3*k1+3*d1...
                               k2+3*k1+3*d1+d2]
class_MC(2).numb_rates      = 8;
class_MC(2).sum_rates       = class_MC(2).rates(class_MC(2).numb_rates);
class_MC(2).rates           = class_MC(2).rates / class_MC(2).sum_rates;
class_MC(2).list            = List;
class_MC(2).list_number     = 0;

%--------------------------------------------------------------------------
class_MC(3).number          = 00021;
class_MC(3)                 = class_MC(2);          

%--------------------------------------------------------------------------
class_MC(4).number          = 20001;
class_MC(4)                 = class_MC(2);          

%--------------------------------------------------------------------------
class_MC(5).number          = 02001;
class_MC(5)                 = class_MC(5);          

%**************************************************************************
%* Transform space
class_MC(6).number          = 00101;
class_MC(6).rates           = [k2 ...
                               k2+k1 k2+2*k1 k2+3*k1...
                            %    k2+k1 k2+2*k1 k2+3*k1 k2+3*k1+k2...
                               k2+3*k1+d1 k2+3*k1+2*d1 k2+3*k1+3*d1];
class_MC(6).numb_rates      = 7;
class_MC(6).sum_rates       = class_MC(6).rates(class_MC)














