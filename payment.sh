#!/bin/bash

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

USERID=$(id -u)
LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
SCRIPT_DIR=$PWD
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log" # /var/log/shell-practice/16-logs/log
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

dnf install python3 gcc python3-devel -y &>>$LOG_FILE
VALIDATE $? "install python3"

id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "creating system user" &>>$LOG_FILE
else
echo -e " user is already exist ... $Y SKIPPING $N"
fi

mkdir /app &>>$LOG_FILE
VALIDATE $? "creating app directory"

curl -L -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip &>>$LOG_FILE
VALIDATE $? "download app code"

rm -rf /app/*
VALIDATE $? "remove old code"

cd /app &>>$LOG_FILE
VALIDATE $? "changing to app directory"

unzip /tmp/payment.zip &>>$LOG_FILE
VALIDATE $? "unzip code"

pip3 install -r requirements.txt  &>>$LOG_FILE
VALIDATE $? "install pip3"

cp $SCRIPT_DIR/payment.service /etc/systemd/system/payment.service &>>$LOG_FILE
VALIDATE $? "cp systemd service"


systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "daemon reload"

systemctl enable payment  &>>$LOG_FILE
VALIDATE $? "enable paymment"

systemctl start payment &>>$LOG_FILE
VALIDATE $? "start payment"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME))
echo -e "script executed in:$Y  $TOTAL_TIME seconds $N"