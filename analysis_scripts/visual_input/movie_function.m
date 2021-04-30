function movie_function(cursor_xy2, players_to_use, sizes, color_to_use, gaze, dpp, FRAME, xmod, n, array, mon, cond_string)

trials_to_use = 1:size(cursor_xy2,3);

% draw cursors
for PLAYER = players_to_use
    X = squeeze(cursor_xy2(1, FRAME, trials_to_use, PLAYER)) + xmod;
    Y = squeeze(cursor_xy2(2, FRAME, trials_to_use, PLAYER));
    cgrect(X', Y', repmat(sizes.cursor, size(X,1),1), repmat(sizes.cursor, size(X,1),1), color_to_use(trials_to_use,:))
end

% draw eye gaze positions
cgpenwid(.5)

for PLAYER = 1:2
    X = squeeze(gaze(1, FRAME, trials_to_use, PLAYER)) + xmod;
    Y = squeeze(gaze(2, FRAME, trials_to_use, PLAYER));
    cgellipse(X', Y', repmat(1/dpp, size(X,1),1), repmat(1/dpp, size(X,1),1), color_to_use(trials_to_use,:))
end

% draw target positions
cgpenwid(2)

for position = 1:n.positions
    cgellipse(array.x(position) + xmod, array.y(position), sizes.target, sizes.target, [1 1 1]) % radius =  292.0774
end


cgtext([cond_string], xmod, 350)

