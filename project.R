library(data.table)
library(caret)
library(ggplot2)
library(doMC)
library(knitr)
library(xtable)
library(randomForest)

registerDoMC(cores = 7)

## You should create a report describing how you built your model, how you used cross validation,
## what you think the expected out of sample error is, and why you made the choices you did.
## You will also use your prediction model to predict 20 different test cases.

## 1. Your submission should consist of a link to a Github repo with your R markdown and compiled HTML
## file describing your analysis. Please constrain the text of the writeup to < 2000 words and the number
## of figures to be less than 5. It will make it easier for the graders if you submit a repo with a gh-pages
## branch so the HTML page can be viewed online (and you always want to make it easy on graders :-).

## 2. You should also apply your machine learning algorithm to the 20 test cases available in the test data
## above. Please submit your predictions in appropriate format to the programming assignment for automated grading.
## See the programming assignment for additional details.

download.pml <- function() {
    download.file("http://d396qusza40orc.cloudfront.net/predmachlearn/pml-training.csv", "pml-training.csv")
    download.file("http://d396qusza40orc.cloudfront.net/predmachlearn/pml-testing.csv", "pml-testing.csv")
}

read.pml <- function(file) {
    fread(file, na.strings=c("#DIV/0!", ""))
}

build.report <- function() {
    knit2html("project.Rmd", "index.html")
}

raw.train <- read.pml("pml-training.csv")
raw.validation <- read.pml("pml-testing.csv")

set.seed(13)

## contains some NA values
na.cols <- raw.train[,sapply(.SD, function(x) any(is.na(x)))]

drop.columns <- function(x) {
    x[,!c("V1", "user_name", "raw_timestamp_part_1", "raw_timestamp_part_2", "cvtd_timestamp", "new_window", "num_window"),with=F]
}

transform.features <- function(x) {
    x[,classe:=factor(classe)]
}

## try only columns that have values
training.features <- drop.columns(raw.train[,eval(names(which(na.cols == F))),with=F])

write.pml.predictions <- function(x) {
    n = length(x)
    for(i in 1:n){
        filename = paste0("problem_id_",i,".txt")
        write.table(x[i],file=filename,quote=FALSE,row.names=FALSE,col.names=FALSE)
    }
}

submit.prediction <- function(x, validation) {
    in.train <- createDataPartition(x$classe, p=.60, list=FALSE)
    train <- x[in.train[,1]]
    model.rf <- train(y=as.factor(train$classe), x=train[,!"classe",with=F], tuneGrid=data.frame(mtry=3), trControl=trainControl(method="none"), method="parRF")  
    write.pml.predictions(predict(model.rf, newdata=drop.columns(validation[,eval(names(which(na.cols == F))[-60]),with=F])))
}
