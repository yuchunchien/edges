% Demo for Edge Boxes (please see readme.txt first).

%% load pre-trained edge detection model and set opts (see edgesDemo.m)
model=load('models/forest/modelBsds'); model=model.model;
model.opts.multiscale=0; model.opts.sharpen=2; model.opts.nThreads=4;

%% set up opts for edgeBoxes (see edgeBoxes.m)
opts = edgeBoxes;
opts.alpha = .85;     % step size of sliding window search
opts.beta  = .95;     % nms threshold for object proposals
opts.minScore = .01;  % min score of boxes to detect
opts.maxBoxes = 1e1;  % max number of boxes to detect

%% detect Edge Box bounding box proposals (see edgeBoxes.m)
allFiles = dir( 'data/JPEGImages/' );
allNames = { allFiles.name };

mapObj = containers.Map('KeyType','char','ValueType','any');
for filename_cell = allNames(1,:)
    %% get the filename with .jpg
    filename = filename_cell{1};
    %disp(filename);
    k = strfind(filename,'.jpg');
    if isempty(k), continue, end
    
    %% categorize filenames with mapObj
    pre_name = filename(1:k-1);
    l = strfind(pre_name,'_');
    key = pre_name(1:l-1);
    if(~isKey(mapObj,key))
        mapObj(key) = {pre_name};        
    else
        tmp = mapObj(key);
        tmp{end+1} = pre_name;
        mapObj(key) = tmp;
    end
end

%% tackle files in each categories
TYPE = {'purple' 'green' 'blue' 'brown' 'red'};
keySet = keys(mapObj);
for key = keySet  % for each category
    %% build BBS map
    mapBBS = containers.Map('KeyType','char','ValueType','any');
    sub_files_cell = mapObj(key{1});
    for file_cell = sub_files_cell
        pre_name = file_cell{1};
        
        %% produce bounding range
        fig_name = strcat(pre_name, '.jpg');
        I = imread( fullfile('data', 'JPEGImages', fig_name) );
        disp(fig_name);
        tic, bbs=edgeBoxes(pre_name,I,model,opts); toc
        mapBBS(pre_name) = bbs;  
    end
    
    %% extract available width of all boxes
    width_record = {[] [] [] [] []};
    
    bbs_keySet = keys(mapBBS);
    for bbs_key_cell = bbs_keySet
        bbs = mapBBS(bbs_key_cell{1});
        [n, m] = size(bbs);
        for idx = 1:n
            score_int = floor(bbs(idx,5));
            type = floor(score_int/10);
            if( type ~= 0 )
                width_record{type}(end+1) = max(bbs(idx,3), bbs(idx,4));
                %bbs(idx,5) = bbs(idx,5) - type*10;
            end
        end
        %% remove type note from score
        %mapBBS(bbs_key_cell{1}) = bbs;
    end

    %% get histogram and set sea lion size
    sealion_size = [ 100 40 60 112 108 ];  % default half size value
    for type = 1:5
        if(~isempty(width_record{type}))
            h = histogram(width_record{type},'BinWidth',10);
            plot_name = strcat(key{1}, '_', TYPE{type}, '.jpg');
            if exist( fullfile('data', 'Hist_Plot', plot_name), 'file' ), 
                delete(fullfile('data', 'Hist_Plot', plot_name));
            end
            saveas(h, fullfile('data', 'Hist_Plot', plot_name) );
            sealion_size(type) = int64((mean(h.BinEdges(([h.Values==max(h.Values) false])))) + 5); 
        end
    end
    
    %% update width and height of bb with score 0
    bbs_keySet = keys(mapBBS);
    for bbs_key_cell = bbs_keySet
        %% update bbs
        bbs = mapBBS(bbs_key_cell{1});
        [n, m] = size(bbs);
        for idx = 1:n
            score_int = floor(bbs(idx,5));
            type = mod(score_int,10);
            if(type~=0)
                bbs(idx,1) = max(bbs(idx,1)-sealion_size(type)/2, 0);
                bbs(idx,2) = max(bbs(idx,2)-sealion_size(type)/2, 0);
                bbs(idx,3) = min(sealion_size(type), 416-bbs(idx,1));
                bbs(idx,4) = min(sealion_size(type), 416-bbs(idx,2));
                %bbs(idx,5) = bbs(idx,5) - type;
            end
        end

        %% output bbs txt file
        % open file
        txt_name = strcat(bbs_key_cell{1}, '.txt');
        txt_file=fopen( fullfile('data', 'GT_Labels', txt_name), 'w');
        
        formatSpec = '%1i %7.6f %7.6f %7.6f %7.6f\n';
        for idx = 1:n
            score_int = floor(bbs(idx,5));
            if(score_int >= 10)
                type = floor(score_int/10);
                bbs(idx,5) = bbs(idx,5) - type*10;
                type = mod(type, 5);
            else
                type = mod(score_int,10);
                bbs(idx,5) = bbs(idx,5) - type;
                type = mod(type, 5);
            end
            A = [type (bbs(idx,1)+bbs(idx,3)/2-1)/416 (bbs(idx,2)+bbs(idx,4)/2-1)/416 bbs(idx,3)/416 bbs(idx,4)/416 ];
            fprintf(txt_file, formatSpec, A);
        end
        fclose(txt_file);
        
        %% plot bbs
        fig_name = strcat(bbs_key_cell{1}, '.jpg');
        I_dot = imread( fullfile('data', 'DotImages', fig_name) );
        hImg=im(I_dot,[],0);
        hold on;
        for i=1:size(bbs,1),
            bbApply('draw', bbs(:,1:5), ['g'], 1, '--'); end
        hold off;
        output_fig_name = strcat(bbs_key_cell{1}, '.jpg');
        if exist( fullfile('data', 'Bound_Result', output_fig_name), 'file' ), 
            delete(fullfile('data', 'Bound_Result', output_fig_name));
        end
        saveas(hImg, fullfile('data', 'Bound_Result', output_fig_name) );
        
    end
end

load handel
sound(y,Fs)
