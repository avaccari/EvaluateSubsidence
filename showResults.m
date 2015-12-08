function showResults(finres, bbox, label, nx, ny)
    cminres = min(finres(:));
    cmaxres = max(finres(:));
    figure;
    set(gcf, 'render', 'opengl');
    imagesc([bbox(1), bbox(3)], [bbox(2), bbox(4)], finres, [cminres, cmaxres]);
    hold on;
    plot(nx(:), ny(:), '.k', 'markersize', 1);
    title(label,'fontsize',20)
    % set(gca,...
    %     'xlim',[xmin,xmax],...
    %     'ylim',[ymin,ymax],...
    %     'Box','on',...
    %     'xtick',[],...
    %     'ytick',[]);
    set(gca,...
        'xlim',[bbox(1),bbox(3)],...
        'ylim',[bbox(2),bbox(4)],...
        'Box','on');
    colorbar('fontsize',14)
end