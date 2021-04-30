function subject_code = generate_subject_code()

number_of_sessions = 20;
number_of_players = 2;
number_of_subjects = number_of_sessions*number_of_players;

subject_code = NaN(number_of_subjects, 3);

for SESSION = 1:number_of_sessions
    for PLAYER = 1:number_of_players
        SUBJECT = (SESSION-1)*number_of_players + PLAYER;
        subject_code(SUBJECT, 1) = SUBJECT;
        subject_code(SUBJECT, 2) = SESSION;
        subject_code(SUBJECT, 3) = PLAYER;
    end
end