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

D = 0.1;            % 扩散系数(m²/s)
g = 9.81;           % 重力加速度(m/s²)
dp = 1e-5;          % 颗粒直径(m)
rho_p = 1500;       % 颗粒密度(kg/m³)
rho_a = 1.225;      % 空气密度(kg/m³)
mu = 1.8e-5;        % 空气动力黏度(Pa·s)
Vd = (g * dp^2 * (rho_p - rho_a)) / (18 * mu); % 沉降速度(m/s)

% 修改为西风（vx负值）
vx =0* ones(nx, ny);  % 西-北方向风
vy = 0* ones(nx, ny);   % y方向风

% 源项设置
% 定义源参数
source.x = round(nx/2);  % x位置
source.y = round(ny/2);    % y位置
source.strength = 10;      % 源强度

% 应用设置
Q = zeros(nx, ny);
Q(source.x, source.y) = source.strength; 

% 边界条件参数
h = 0.1;            % 传质系数
C_ext = 0;          % 外部环境浓度

%% 初始化
C = zeros(nx, ny);   % 初始浓度场
C_prev = C;

%% 主循环（时间推进）
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
    
    %--- 边界条件处理 ---
    % 道路边界（南侧：混合边界）
    j = 1;
    for i = 1:nx
        C(i,j) = (D*C(i,j+1)/dy + h*C_ext) / (D/dy + h);
    end
    
    % 建筑表面（北侧：无穿透条件）
    j = ny;
    C(:,j) = C(:,j-1);
    
    % 开放边界（左右侧：零梯度）
    C(1,:) = C(2,:);     % 左边界
    C(nx,:) = C(nx-1,:); % 右边界
end

%% 可视化
[X, Y] = meshgrid(linspace(0,Lx,nx), linspace(0,Ly,ny));
contourf(X, Y, C', 20, 'LineColor', 'none');
colorbar;
title('花粉浓度分布（无风场景）');
xlabel('x (m)'); ylabel('y (m)');