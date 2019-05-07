function CCA = run_CCA_LOO(behav_data,MCA,num_comps,num_modes,norm_prior)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

%hard code
DocsPath = '/Users/luke/Documents/Projects/StrokeNet/Docs/';

N = size(behav_data,1);
num_meas = size(behav_data,2);

CCA.A = zeros(num_meas,N,num_modes);
CCA.B = zeros(num_comps,N,num_modes);
CCA.U = zeros(N,N,num_modes);
CCA.V = zeros(N,N,num_modes);

for subj = 1:N
    
    % get the x (behaviour) variable
    xTrain = behav_data;
    xTrain(subj,:) = [];
    xTrainCentre = mean(xTrain);
    xTrainStd = std(xTrain);
    xTest = behav_data(subj,:);
    
    if norm_prior==0
        % normalise the training behavioural data
        xTrain = normal_transform(xTrain); 
    end
    
    %get the y (brain) variable after dimensionality reduction
    % this was computed earlier in the script to save time (many
    % repetitions of MCA on a large matrix is slow).
    yTrain = MCA.Indweights(:,:,subj);
    yTrain = yTrain(:,1:num_comps);
    yTest  = MCA.LOO_Indweights(subj,:);
    yTest  = yTest(1:num_comps);
    
    %This computes CCA on the training data
    [A,B,r,U,V] = canoncorr(xTrain,yTrain);

    %Only interested in the first two Modes
    for Mode = 1:num_modes

        % build linear regression model using U and V
        y = U(:,Mode);                          % want to predict U
        x = [ones(length(V(:,1)),1),V(:,Mode)]; % from V
        beta = regress(y,x);                    % get regression coefficient

        % Calculate held-out V using the training data weights
        % see matlab help: V = (Y-repmat(mean(Y),N,1))*B
        Vpred = yTest * B(:,Mode);

        % Calculate held-out U via linear regression equation from training set
        Upred = beta(1) + (Vpred * beta(2));

        % Apply weights, in the opposite direction, to get raw behaviour
        xPred(subj,:,Mode) = Upred ./ A(:,Mode);

        if norm_prior==0
            % transform back into behaviour distribution
            xPred(subj,:,Mode) = xPred(subj,:,Mode).*xTrainStd + xTrainCentre;
        end
    
        % save the output (note the organisation)
        CCA.r(subj,Mode) = r(Mode);
        CCA.A(:,subj,Mode) = A(:,Mode);
        CCA.B(:,subj,Mode) = B(:,Mode);
        
        CCA.V(subj,subj,Mode) = NaN; %no loading for left out.
        idx = CCA.V(:,subj,Mode)==0;
        CCA.V(idx,subj,Mode) = V(:,Mode);
        
        CCA.U(subj,subj,Mode) = NaN; %no loading for left out.
        CCA.U(idx,subj,Mode) = U(:,Mode);
    end
end
CCA.predicted_values = xPred;
CCA.real_values = behav_data;

for i = 1:num_meas
   [CCA.predicted_r(i),CCA.predicted_p(i)] = corr(CCA.real_values(:,i),CCA.predicted_values(:,i,1));
    %disp(['For variable: ',num2str(i),', r = ',num2str(CCA.predicted_r),', p = ',num2str(CCA.predicted_p)])
end
end

