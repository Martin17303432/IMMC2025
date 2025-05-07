%% 初始化参数
clear; clc;

% 场景参数
wind_speed_high = [3, 5, 8]; % 高空风速(m/s)
scenarios = {'3m/s', '5m/s', '8m/s'};
z_high = 10;      % 高空测量高度(m)
z_ground = 2;     % 地面参考高度(m)
alpha = 0.3;      % 地表粗糙度指数（城市）
beta = 0.6;       % 遮挡衰减因子
theta = 180;       % 风向与出行方向夹角(度)，需根据实际数据调整

% 出行者参数
v_b = 15 / 3.6;   % 骑行速度(m/s)，15km/h转m/s
m = 75;           % 总质量(kg)
Cd = 0.9;         % 风阻系数
A = 0.6;          % 迎风面积(m²)
rho = 1.225;      % 空气密度(kg/m³)
g = 9.8;          % 重力加速度

% 路径参数（示例数据，来自任务表格）
paths = struct(...
    'Name', {'A', 'B', 'C', 'D'},...
    'Length', [18.8, 20.5, 16.8, 18.3],...    % 长度(km)
    'Slope', [2.1, 1.5, 3.2, 2.1],...         % 平均坡度(%)
    'd_i', [0.55, 0.15, 0.65, 0.45],...       % 建筑遮挡比例
    'mu', [0.007, 0.005, 0.012, 0.007]...     % 滚动摩擦系数
);

%% 计算函数定义
% 地面风速计算
w_ground = @(W_high) W_high * (z_ground/z_high)^alpha;

% 修正风速计算（考虑遮挡）
w_corrected = @(w_ground, d_i) w_ground .* (1 - beta * d_i);

% 相对风速计算（矢量合成）
v_r = @(w, theta_deg) sqrt(w^2 + v_b^2 - 2*w*v_b*cosd(theta_deg));

% 风阻力功率计算
P_air = @(v_r_val) 0.5 * rho * Cd * A * v_b * (v_b - w_ground * cosd(theta)) * v_r_val;

% 滚动阻力功率
P_roll = @(mu_val) mu_val * m * g * v_b * cosd(atand(slope_percent/100));

% 坡度功率
P_slope = @(slope_percent) m * g * v_b * sind(atand(slope_percent/100));

% 总功率计算
total_power = @(P_air, P_roll, P_slope) P_air + P_roll + P_slope;

% 总能耗计算
 % 能量消耗（功率×时间）
    time = (length(scenarios) * 1000) / v_b; % 时间(s)
    E_total_val = @(total_power)total_power * v_b * time / 1000; % 转换为千焦(kJ)

% 舒适度计算函数
comfort_grade = @(slope_percent) ...
    (slope_percent <= 2) * 1 + ...
    (slope_percent > 2 & slope_percent <= 20) .* (1 - (slope_percent-2)/18) + ...
    (slope_percent > 20) * 0;

comfort_wind = @(v_r_val) ...
    (v_r_val <= 4) * 1 + ...
    (v_r_val > 4 & v_r_val <= 15) .* (1 - (v_r_val-4)/11) + ...
    (v_r_val > 15) * 0;

comfort_road = @(mu_val) 1 - mu_val.^2;

%% 多场景计算
% 权重设置
weights = struct('energy', 0.3, 'comfort', 0.7);

% 结果存储
results = cell(length(scenarios), 1);

%% 修正后的函数定义
v_r = @(w, theta_deg) sqrt(w.^2 + v_b^2 - 2.*w.*v_b.*cosd(theta_deg));
%% 修正后的循环计算部分
for s = 1:length(scenarios)
    W_high = wind_speed_high(s);
    current_scenario = scenarios{s};
    
    for p = 1:length(paths)
  
    % 计算时间（长度单位：km转m，速度单位：m/s）
    paths(p).Time = (paths(p).Length * 1000) / v_b;  % 单位：秒

        % 地面风速修正
        w_g = w_ground(W_high);
        w_corr = w_corrected(w_g, paths(p).d_i); % 标量计算
        
        % 相对风速
       vr = v_r(w_corr, theta); % 输入为标量
        
        % 功率计算（元素级运算）
        P_air_val = 0.5 * rho * Cd * A * v_b .* (v_b - w_corr .* cosd(theta)) .* vr;
        P_roll_val = paths(p).mu * m * g * v_b .* cosd(atand(paths(p).Slope/100));
        P_slope_val = m * g * v_b .* sind(atand(paths(p).Slope/100));
        P_total = P_air_val + P_roll_val + P_slope_val;

         % 能量消耗（功率×时间）
    time = (paths(p).Length * 1000)  / vr(p); % 时间(s)
  
    E_total_val =P_total .* time / 1000; % 转换为千焦(kJ)


        % 舒适度计算
        c_grade = comfort_grade(paths(p).Slope);
        c_wind = comfort_wind(vr);
        c_road = comfort_road(paths(p).mu);
        total_comfort = 0.4*c_grade + 0.4*c_wind + 0.2*c_road; % 假设权重
        
        % 存储结果
        results{s}(p,:) = [vr(p), E_total_val(p), total_comfort(p)];
    
    end
      Time= max(paths(p).Length * 1000)  / v_b; % 时间(s)
          IN=250 .*  Time/ 1000;
end

%% 结果展示（示例）
disp('=================================================================')

fprintf('%-6s %-4s  %-10s %-10s  %-10s  %-10s \n',... 
    '场景', '路线', '修正风速','能耗(KJ)', '舒适度', '综合评分')



for s = 1:length(scenarios)
    for p = 1:length(paths)
        score = weights.energy*(1-(results{s}(p,2)/IN)) + ... % 假设归一化
                weights.comfort*results{s}(p,3);
        fprintf('%-6s %-4s  %-10.3f   %-10.3f %-10.3f  %-10.3f \n',...
                scenarios{s}, paths(p).Name, results{s}(p,1), results{s}(p,2), results{s}(p,3),score*100);
    end
end