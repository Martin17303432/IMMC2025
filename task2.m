%% 初始化参数
clear; clc;

% 定义路线参数（正确初始化结构体数组）
route_data = [
    struct('Name', 'A', 'H_W', 1.4, 'theta_deg', 40);
    struct('Name', 'B', 'H_W', 0.6, 'theta_deg', 60);
    struct('Name', 'C', 'H_W', 1.8, 'theta_deg', 25);
    struct('Name', 'D', 'H_W', 1.2, 'theta_deg', 45)
];

% 场景参数
v_amb_list = [3, 5, 8]; % 环境风速(m/s)
beta = 0.6;             % 遮挡衰减因子
d_i = 0.5;              % 遮挡距离比例
v_th = 5;               % 阈值风速(m/s)

%% 计算修正因子
for i = 1:length(route_data)
    H_W = route_data(i).H_W;
    theta_deg = route_data(i).theta_deg;
    
    % 计算 alpha_v
    ln_HW = log(H_W);
    cos_theta = cosd(theta_deg);
    alpha_v = 1 + 0.35 * ln_HW * cos_theta;
    
    % 修正因子
    correction_factor = (1 - beta*d_i) * alpha_v;
    route_data(i).correction_factor = correction_factor;
end

%% 计算修正前/后的结果（预分配数组）
num_scenarios = length(v_amb_list) * length(route_data);
pre_results = cell(num_scenarios, 6);  % 修正前
post_results = cell(num_scenarios, 6); % 修正后
row = 1;

for v_idx = 1:length(v_amb_list)
    v_amb = v_amb_list(v_idx);
    
    for r_idx = 1:length(route_data)
        % 修正前的风速（直接使用环境风速）
        v_eff_pre = v_amb; % 未应用修正模型
        
        % 修正后的风速
        correction_factor = route_data(r_idx).correction_factor;
        v_eff_post = v_amb * correction_factor;
        
        % ----------- 公共计算逻辑（前后一致）------------
        % 总功率
        P_total_pre = 100 + 20*v_eff_pre + 0.5*v_eff_pre^2;
        P_total_post = 100 + 20*v_eff_post + 0.5*v_eff_post^2;
        
        % 风速舒适度
        delta_pre = max(0, v_eff_pre - v_th);
        wind_comfort_pre = 1 - 0.05 * delta_pre^2;
        wind_comfort_pre = max(min(wind_comfort_pre, 1), 0);
        
        delta_post = max(0, v_eff_post - v_th);
        wind_comfort_post = 1 - 0.05 * delta_post^2;
        wind_comfort_post = max(min(wind_comfort_post, 1), 0);
        
        % 综合评分
        score_pre = 95 - 2*v_eff_pre - 0.1*P_total_pre;
        score_pre = max(score_pre, 40);
        
        score_post = 95 - 2*v_eff_post - 0.1*P_total_post;
        score_post = max(score_post, 40);
        
        % ----------- 保存结果 ------------
        % 修正前
        pre_results(row, :) = { ...
            v_amb, ...
            route_data(r_idx).Name, ...
            v_eff_pre, ...
            P_total_pre, ...
            wind_comfort_pre, ...
            score_pre ...
        };
        
        % 修正后
        post_results(row, :) = { ...
            v_amb, ...
            route_data(r_idx).Name, ...
            v_eff_post, ...
            P_total_post, ...
            wind_comfort_post, ...
            score_post ...
        };
        
        row = row + 1;
    end
end

%% 输出修正前表格
fprintf('\n============ 修正前模型结果 ============\n');
fprintf('| %-8s | %-4s | %-12s | %-12s | %-15s | %-12s |\n',...
    '场景(m/s)', '路线', '风速', '总功率(W)', '风速舒适度', '综合评分');
fprintf('|----------|------|--------------|--------------|-----------------|--------------|\n');
for i = 1:size(pre_results,1)
    fprintf('| %-8.0f | %-4s | %-12.1f | %-12.0f | %-15.2f | %-12.0f |\n',...
        pre_results{i,1}, pre_results{i,2}, pre_results{i,3}, pre_results{i,4}, pre_results{i,5}, pre_results{i,6});
end

%% 输出修正后表格
fprintf('\n============ 修正后模型结果 ============\n');
fprintf('| %-8s | %-4s | %-12s | %-12s | %-15s | %-12s |\n',...
    '场景(m/s)', '路线', '修正风速', '总功率(W)', '风速舒适度', '综合评分');
fprintf('|----------|------|--------------|--------------|-----------------|--------------|\n');
for i = 1:size(post_results,1)
    fprintf('| %-8.0f | %-4s | %-12.1f | %-12.0f | %-15.2f | %-12.0f |\n',...
        post_results{i,1}, post_results{i,2}, post_results{i,3}, post_results{i,4}, post_results{i,5}, post_results{i,6});
end