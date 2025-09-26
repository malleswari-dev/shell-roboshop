#!/bin/bash

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

USERID=$(id -u)
LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
SCRIPT_DIR=$PWD
MONGODB_HOST=mongodb.malleswari.fun
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
# /var/log/shell-practice/16-logs/log
START_TIME=$(date +%s)

mkdir -p $LOGS_FOLDER
echo "script started executed at:$(date)"  | tee -a $LOG_FILE

if [ $USERID -ne 0 ]; then
    echo "ERROR:please run this script with root privilage"
    exit 1 # failure is othher than 0
fi     
# functions receives inputs through args like shell script args.
VALIDATE () { 
    if [ $1 -ne 0 ] ; then
        echo -e "  $2 is $R failure $N"  | tee -a $LOG_FILE
        exit 1
    else
        echo -e " $2 is $G success $N"  | tee -a $LOG_FILE
    fi
}

dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "disable nodejs"

dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "enable nodejs 20"

dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "install nodejs"

id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "creating system user" &>>$LOG_FILE
else
echo -e " user is already exist ... $Y SKIPPING $N"
fi

mkdir -p /app &>>$LOG_FILE
VALIDATE $? "creating app directory"

curl -L -o /tmp/user.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip &>>$LOG_FILE
VALIDATE $? "downloading user application"

cd /app 
VALIDATE $? "changing to app directory"

rm -rf /app/*
VALIDATE $? "removing old code"

unzip /tmp/user.zip &>>$LOG_FILE
VALIDATE $? "unzip code"

npm install &>>$LOG_FILE
VALIDATE $? "install dependencies"

cp $SCRIPT_DIR/user.service /etc/systemd/system/user.service &>>$LOG_FILE
VALIDATE $? "copy systemctl service"

systemctl daemon-reload &>>$LOG_FILE
systemctl enable user  &>>$LOG_FILE
VALIDATE $? "enable user"

systemctl start user &>>$LOG_FILE
VALIDATE $? "start user"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME))
echo -e "script executed in:$Y  $TOTAL_TIME seconds $N"