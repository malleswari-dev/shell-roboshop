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

dnf module disable nginx -y &>>$LOG_FILE
VALIDATE $? "disable nginx"

dnf module enable nginx:1.24 -y &>>$LOG_FILE
VALIDATE $? "enable nginx:1.24"

dnf install nginx -y &>>$LOG_FILE
VALIDATE $? "install nginx"

systemctl enable nginx  &>>$LOG_FILE
VALIDATE $? "enable nginx"

systemctl start nginx  &>>$LOG_FILE
VALIDATE $? "start nginx"

rm -rf /usr/share/nginx/html/*  &>>$LOG_FILE
VALIDATE $? "remove old code"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>>$LOG_FILE
VALIDATE $? "download app code"

cd /usr/share/nginx/html  &>>$LOG_FILE
VALIDATE $? "changing to directory"

unzip /tmp/frontend.zip &>>$LOG_FILE
VALIDATE $? "unzip code"

cp $SCRIPT_DIR/nginx.conf /etc/nginx/nginx.conf &>>$LOG_FILE
VALIDATE $? "cp systemd service"

systemctl restart nginx &>>$LOG_FILE
VALIDATE $? "restart nginx"