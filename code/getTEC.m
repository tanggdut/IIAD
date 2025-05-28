function getTEC(obsfile, navfile, outpath, opt)
    % 检查观测文件
    [ofpath, oname, ext] = fileparts(obsfile);
    if ~isempty(ofpath)
        ofpath = [ofpath, filesep];
    end
    file_obs = dir(fullfile(ofpath, [oname, ext]));
    nof = length(file_obs);
    if nof == 0
        error('No observation file !!!\n');
    end

    % 检查导航文件
    [nfpath, nname, ext] = fileparts(navfile);
    if ~isempty(nfpath)
        nfpath = [nfpath, filesep];
    end
    file_nav = dir(fullfile(nfpath, [nname, ext]));
    nnf = length(file_nav);
    if nnf == 0
        error('No navigation file !!!\n');
    end

    % 确保输出路径存在
    if ~exist(outpath, 'dir')
        mkdir(outpath);
    end

    % 计算 TEC
    for nsta = 1:nof
        ofile = fullfile(ofpath, file_obs(nsta).name);
        olen = length(file_obs(nsta).name);
        if olen < 13
            cdoy = file_obs(nsta).name(5:7); % 版本 2
        else
            cdoy = file_obs(nsta).name(17:19); % 版本 3
        end

        % 查找匹配的导航文件
        vs = 0;
        for j = 1:nnf
            if ismember(cdoy, file_nav(j).name)
                nfile = fullfile(nfpath, file_nav(j).name);
                vs = 1;
                break;
            end
        end
        if vs == 0
            disp(['No navigation file for !!!', file_obs(nsta).name]);
            continue;
        end

        disp(['-> Processing station ', num2str(nsta), '/', num2str(nof)]);

        % 读取观测文件和导航文件
        obsdata = readobs(ofile, opt.navsys);
        navdata = readnav(nfile);

        % 生成 TEC 文件
        [~, fname, ~] = fileparts(ofile);
        tecfile = fullfile(outpath, [fname, '.tec']);
        calTEC(opt, obsdata, navdata, tecfile, nsta);
    end

    disp('TEC processing completed.');
end