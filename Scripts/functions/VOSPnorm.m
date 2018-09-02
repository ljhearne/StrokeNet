function new_score = VOSPnorm(score,age)
% enter score and age
% VOSPnorm(score,age)
% returns 1 if impaired

if age < 50
    new_score = score < 17;
else
    new_score = score < 16;
end

end

