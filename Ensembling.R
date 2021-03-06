#Loading the required libraries
library('caret')

#Seeting the random seed
set.seed(1)

#Loading the hackathon dataset
data<-read.csv(url('https://datahack.analyticsvidhya.com/media/train_file/train_u6lujuX_CVtuZ9i.csv'))

#Let's see if the structure of dataset data 
str(data)

'data.frame':	614 obs. of  13 variables:
  $ Loan_ID          : Factor w/ 614 levels "LP001002","LP001003",..: 1 2 3 4 5 6 7 8 9 10 ...
$ Gender           : Factor w/ 3 levels "","Female","Male": 3 3 3 3 3 3 3 3 3 3 ...
$ Married          : Factor w/ 3 levels "","No","Yes": 2 3 3 3 2 3 3 3 3 3 ...
$ Dependents       : Factor w/ 5 levels "","0","1","2",..: 2 3 2 2 2 4 2 5 4 3 ...
$ Education        : Factor w/ 2 levels "Graduate","Not Graduate": 1 1 1 2 1 1 2 1 1 1 ...
$ Self_Employed    : Factor w/ 3 levels "","No","Yes": 2 2 3 2 2 3 2 2 2 2 ...
$ ApplicantIncome  : int  5849 4583 3000 2583 6000 5417 2333 3036 4006 12841 ...
$ CoapplicantIncome: num  0 1508 0 2358 0 ...
$ LoanAmount       : int  NA 128 66 120 141 267 95 158 168 349 ...
$ Loan_Amount_Term : int  360 360 360 360 360 360 360 360 360 360 ...
$ Credit_History   : int  1 1 1 1 1 1 1 0 1 1 ...
$ Property_Area    : Factor w/ 3 levels "Rural","Semiurban",..: 3 1 3 3 3 3 3 2 3 2 ...
$ Loan_Status      : Factor w/ 2 levels "N","Y": 2 1 2 2 2 2 2 1 2 1 ...

#Does the data contain missing values
sum(is.na(data))
[1] 86

#Imputing missing values using mdeian
preProcValues <- preProcess(data, method = c("medianImpute","center","scale"))

library('RANN')
data_processed <- predict(preProcValues, data)
sum(is.na(data_processed))
[1] 0


#Spliting training set into two parts based on outcome: 75% and 25%
index <- createDataPartition(data_processed$Loan_Status, p=0.75, list=FALSE)
trainSet <- data_processed[ index,]
testSet <- data_processed[-index,]

#Defining the training controls for multiple models
fitControl <- trainControl(
  method = "repeatedcv",
  number = 5,
  repeats = 5,
  savePredictions = 'final',
  classProbs = T)

#Defining the predictors and outcome
predictors<-c("Credit_History", "LoanAmount", "Loan_Amount_Term", "ApplicantIncome", 
  "CoapplicantIncome")
outcomeName<-'Loan_Status'

#Training the random forest model
model_rf<-train(trainSet[,predictors],trainSet[,outcomeName],method='rf',trControl=fitControl,tuneLength=3)

#Predicting using random forest model
testSet$pred_rf<-predict(object = model_rf,testSet[,predictors])

#Checking the accuracy of the random forest model 
confusionMatrix(testSet$Loan_Status,testSet$pred_rf)

Confusion Matrix and Statistics

Reference
Prediction  N  Y
N 28 20
Y  9 96

Accuracy : 0.8105          
95% CI : (0.7393, 0.8692)
No Information Rate : 0.7582          
P-Value [Acc > NIR] : 0.07566         

Kappa : 0.5306          
Mcnemar's Test P-Value : 0.06332         

Sensitivity : 0.7568          
Specificity : 0.8276          
Pos Pred Value : 0.5833          
Neg Pred Value : 0.9143          
Prevalence : 0.2418          
Detection Rate : 0.1830          
Detection Prevalence : 0.3137          
Balanced Accuracy : 0.7922          

'Positive' Class : N


#Training the knn model
model_knn<-train(trainSet[,predictors],trainSet[,outcomeName],method='knn',trControl=fitControl,tuneLength=3)

#Predicting using knn model
testSet$pred_knn<-predict(object = model_knn,testSet[,predictors])

#Checking the accuracy of the random forest model 
confusionMatrix(testSet$Loan_Status,testSet$pred_knn)

Confusion Matrix and Statistics

Reference
Prediction   N   Y
N  29  19
Y   2 103

Accuracy : 0.8627         
95% CI : (0.7979, 0.913)
No Information Rate : 0.7974         
P-Value [Acc > NIR] : 0.0241694      

Kappa : 0.6473         
Mcnemar's Test P-Value : 0.0004803      

Sensitivity : 0.9355         
Specificity : 0.8443         
Pos Pred Value : 0.6042         
Neg Pred Value : 0.9810         
Prevalence : 0.2026         
Detection Rate : 0.1895         
Detection Prevalence : 0.3137         
Balanced Accuracy : 0.8899         

'Positive' Class : N  

#Training the Logistic regression model
model_lr<-train(trainSet[,predictors],trainSet[,outcomeName],method='glm',trControl=fitControl,tuneLength=3)

#Predicting using knn model
testSet$pred_lr<-predict(object = model_lr,testSet[,predictors])

#Checking the accuracy of the random forest model 
confusionMatrix(testSet$Loan_Status,testSet$pred_lr)

Confusion Matrix and Statistics

Reference
Prediction   N   Y
N  29  19
Y   2 103

Accuracy : 0.8627         
95% CI : (0.7979, 0.913)
No Information Rate : 0.7974         
P-Value [Acc > NIR] : 0.0241694      

Kappa : 0.6473         
Mcnemar's Test P-Value : 0.0004803      

Sensitivity : 0.9355         
Specificity : 0.8443         
Pos Pred Value : 0.6042         
Neg Pred Value : 0.9810         
Prevalence : 0.2026         
Detection Rate : 0.1895         
Detection Prevalence : 0.3137         
Balanced Accuracy : 0.8899         

'Positive' Class : N  


#Predicting the probabilities
testSet$pred_rf_prob<-predict(object = model_rf,testSet[,predictors],type='prob')
testSet$pred_knn_prob<-predict(object = model_knn,testSet[,predictors],type='prob')
testSet$pred_lr_prob<-predict(object = model_lr,testSet[,predictors],type='prob')

#Taking average of predictions
testSet$pred_avg<-(testSet$pred_rf_prob$Y+testSet$pred_knn_prob$Y+testSet$pred_lr_prob$Y)/3

#Splitting into binary classes at 0.5
testSet$pred_avg<-as.factor(ifelse(testSet$pred_avg>0.5,'Y','N'))


#The majority vote
testSet$pred_majority<-as.factor(ifelse(testSet$pred_rf=='Y' & testSet$pred_knn=='Y','Y',ifelse(testSet$pred_rf=='Y' & testSet$pred_lr=='Y','Y',ifelse(testSet$pred_knn=='Y' & testSet$pred_lr=='Y','Y','N'))))


#Taking weighted average of predictions
testSet$pred_weighted_avg<-(testSet$pred_rf_prob$Y*0.25)+(testSet$pred_knn_prob$Y*0.25)+(testSet$pred_lr_prob$Y*0.5)

#Splitting into binary classes at 0.5
testSet$pred_weighted_avg<-as.factor(ifelse(testSet$pred_weighted_avg>0.5,'Y','N'))




#Logistic Regression
lr<-train(testSet[,c('pred_rf','pred_knn','pred_lr')],testSet[,'Loan_Status'],method='glm',trControl=fitControl,tuneLength=3)





fitControl <- trainControl(
method = "cv",
number = 10,
savePredictions = 'final',
classProbs = T)

#Defining the predictors and outcome
predictors<-c("Credit_History", "LoanAmount", "Loan_Amount_Term", "ApplicantIncome", 
"CoapplicantIncome")
outcomeName<-'Loan_Status'

#Training the random forest model
model_rf<-train(trainSet[,predictors],trainSet[,outcomeName],method='rf',trControl=fitControl,tuneLength=3)


#Training the knn model
model_knn<-train(trainSet[,predictors],trainSet[,outcomeName],method='knn',trControl=fitControl,tuneLength=3)

#Training the logistic regression model
model_lr<-train(trainSet[,predictors],trainSet[,outcomeName],method='glm',trControl=fitControl,tuneLength=3)


trainSet$OOF_pred_rf<-model_rf$pred$Y[order(model_rf$pred$rowIndex)]
trainSet$OOF_pred_knn<-model_knn$pred$Y[order(model_knn$pred$rowIndex)]
trainSet$OOF_pred_lr<-model_lr$pred$Y[order(model_lr$pred$rowIndex)]

testSet$OOF_pred_rf<-predict(model_rf,testSet[predictors],type='prob')$Y
testSet$OOF_pred_knn<-predict(model_knn,testSet[predictors],type='prob')$Y
testSet$OOF_pred_lr<-predict(model_lr,testSet[predictors],type='prob')$Y

predictors_top<-c('OOF_pred_rf','OOF_pred_knn','OOF_pred_lr')

model_gbm<-train(trainSet[,predictors_top],trainSet[,outcomeName],method='gbm',trControl=fitControl,tuneLength=3)
model_glm<-train(trainSet[,predictors_top],trainSet[,outcomeName],method='glm',trControl=fitControl,tuneLength=3)


#predict using GBM top layer model
testSet$gbm_stacked<-predict(model_gbm,testSet[,predictors_top])

#predict using logictic regression top layer model
testSet$glm_stacked<-predict(model_glm,testSet[,predictors_top])
