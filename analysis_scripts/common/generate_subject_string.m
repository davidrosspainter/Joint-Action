function [SESSION, PLAYER, STR] = generate_subject_string(SUBJECT, subject_code)

SESSION = subject_code(SUBJECT,2);
PLAYER = subject_code(SUBJECT,3);

if subject_code(SUBJECT,1) < 10
    STR.S = [ '0' num2str( subject_code(SUBJECT,1) ) ]; 
else
    STR.S = num2str( subject_code(SUBJECT,1) );
end

if subject_code(SUBJECT,2) < 10
    STR.P = [ '0' num2str( subject_code(SUBJECT,2) ) ]; 
else
    STR.P = num2str( subject_code(SUBJECT,2) );
end

if subject_code(SUBJECT,3) < 10
    STR.I = [ '0' num2str( subject_code(SUBJECT,3) ) ]; 
else
    STR.I = num2str( subject_code(SUBJECT,3) );
end

STR.SUBJECT = [ 'S' STR.S '.P' STR.P '.' STR.I ];