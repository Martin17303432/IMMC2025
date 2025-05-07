%% 参数设置
Lx = 100;           % x方向长度(m)
Ly = 100;           % y方向长度(m)
nx = 50;            % x方向网格数
ny = 50;            % y方向网格数
dx = Lx/(nx-1);     % x方向步长
dy = Ly/(ny-1);     % y方向步长
dt = 0.1;           % 时间步长(s)
T_total = 50;       % 总模拟时间(s)
nt = T_total/dt;    % 时间步数

D = 5;            % 扩散系数(m²/s)
g = 9.81;           % 重力加速度(m/s²)
dp = 1e-5;          % 颗粒直径(m)
rho_p = 1500;       % 颗粒密度(kg/m³)
rho_a = 1.225;      % 空气密度(kg/m³)
mu = 1.8e-5;        % 空气动力黏度(Pa·s)
Vd = (g * dp^2 * (rho_p - rho_a)) / (18 * mu); % 沉降速度(m/s)

% 风速场定义
vx = 2.0 * ones(nx, ny);  % 东风
vy = 1* ones(nx, ny);  % 无y方向风

% 定义多个污染源
sources = [
   struct('x', round(nx/4), 'y', round(ny/3), 'strength', 10),  % 左上部
   struct('x', round(3*nx/4), 'y', round(2*ny/3), 'strength', 15), % 右下部
   struct('x', round(nx/2), 'y', round(ny/2), 'strength', 20)      % 中心
];

% 初始化Q矩阵并叠加源
Q = zeros(nx, ny);
for k = 1:length(sources)
    src = sources(k);
    Q(src.x, src.y) = Q(src.x, src.y) + src.strength;
end

% 边界条件参数
h = 0.1;            % 传质系数
C_ext = 0;          % 外部环境浓度

%% 初始化与主循环（保持不变）
C = zeros(nx, ny);
C_prev = C;

% 主循环（时间推进）
for t = 1:nt
    C_prev = C;
    
    for i = 2:nx-1
        for j = 2:ny-1
            %--- 修正的对流项 ---
            % x方向
            if vx(i,j) >= 0
                adv_x = vx(i,j) * (C_prev(i,j) - C_prev(i-1,j)) / dx;
            else
                adv_x = vx(i,j) * (C_prev(i+1,j) - C_prev(i,j)) / dx;
            end
            
            % y方向
            if vy(i,j) >= 0
                adv_y = vy(i,j) * (C_prev(i,j) - C_prev(i,j-1)) / dy;
            else
                adv_y = vy(i,j) * (C_prev(i,j+1) - C_prev(i,j)) / dy;
            end
            
            % 扩散项
         diff_x = (C_prev(i+1,j) - 2*C_prev(i,j) + C_prev(i-1,j)) / dx^2;
         diff_y = (C_prev(i,j+1) - 2*C_prev(i,j) + C_prev(i,j-1)) / dy^2;
            
            % 更新方程
            C(i,j) = C_prev(i,j) + dt*(...
                -adv_x - adv_y ...          % 对流项
                + D*(diff_x + diff_y) ...   % 扩散项
                - Vd*C_prev(i,j) ...        % 沉降项
                + Q(i,j));                  % 源项
        end 
        end
    end

%% 可视化
[X, Y] = meshgrid(linspace(0,Lx,nx), linspace(0,Ly,ny));
contourf(X, Y, C', 20, 'LineColor', 'none');
colorbar;
title('花粉浓度分布（多花粉源扩散系数5）');
xlabel('x (m)'); ylabel('y (m)');