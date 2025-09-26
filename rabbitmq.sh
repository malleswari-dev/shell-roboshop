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

cp $SCRIPT_DIR/rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo &>>$LOG_FILE
VALIDATE $? "copy systemd service"

dnf install rabbitmq-server -y &>>$LOG_FILE
VALIDATE $? "install rabbitmq"

systemctl enable rabbitmq-server &>>$LOG_FILE
VALIDATE $? "enable rabbitmq"

systemctl start rabbitmq-server &>>$LOG_FILE
VALIDATE $? "start rabbitmq"

rabbitmqctl add_user roboshop roboshop123 &>>$LOG_FILE
VALIDATE $? "add user"

rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*" &>>$LOG_FILE
VALIDATE $? "rabbitmq permissions"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME))
echo -e "script executed in:$Y  $TOTAL_TIME seconds $N"