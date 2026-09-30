_SHARED = {
    infobox = {
        cfg = {
            startX = 30, startY = 39;
            gap = 12;
            padding = 16;
            minW = 200, maxW = 360;
            badgeH = 25, badgeGap = 8;
            bottomPad = 20;
            radius = 10, badgeRadius = 6;
            lineSpacing = 1.15;
            maxVisible = 5;
            minTime = 3000, maxTime = 9000;
            timePerChar = 45;
            fadeSpeed = 10, moveSpeed = 12;
            slideDist = 30;
            showProgress = true;
        };
        alpha = {title = 235, counter = 110, desc = 165, card = 225, badge = 28};
        types = {
            success = {title = 'Success', color = {156, 235, 118}, card = {20, 26, 21}, icon = 'ic_success', iw = 10, ih = 9};
            error = {title = 'Error', color = {238, 107, 107}, card = {28, 20, 20}, icon = 'ic_error', iw = 10, ih = 9};
            warning = {title = 'Warning', color = {247, 186, 79}, card = {28, 25, 18}, icon = 'ic_warning', iw = 10, ih = 9};
            about = {title = 'Sobre', color = {72, 145, 255}, card = {18, 22, 30}, icon = 'ic_about', iw = 4,  ih = 10};
        };
        aliases = {
            info = 'about', warn = 'warning', ok = 'success', err = 'error',
        };
    };
}