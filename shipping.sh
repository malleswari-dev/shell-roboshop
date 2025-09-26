#!/bin/bash

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

USERID=$(id -u)
LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
SCRIPT_DIR=$PWD
MYSQL_HOST=mysql.malleswari.fun
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

dnf install maven -y
VALIDATE $? "install maven"

id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "creating system user" &>>$LOG_FILE
else
echo -e " user is already exist ... $Y SKIPPING $N"
fi

mkdir -p /app 
VALIDATE $? "creating app directory"

curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip 
VALIDATE $? "download code"

cd /app 
VALIDATE $? "changing to app directory"

rm -rf /app/*
VALIDATE $? "removing old code"

unzip /tmp/shipping.zip
VALIDATE $? "unzip code"

mvn clean package 
VALIDATE $? "cleaning package"

mv target/shipping-1.0.jar shipping.jar 
VALIDATE $? "moving to shipping.jar"

cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service
VALIDATE $? "copy systemd service"

systemctl daemon-reload
VALIDATE $? "daemon reload"

systemctl enable shipping 
VALIDATE $? "enable shipping"

systemctl start shipping
VALIDATE $? "start shipping"

dnf install mysql -y
VALIDATE $? "install mysql"

mysql -h $MYSQL_HOST -uroot -pRoboShop@1 -e 'use cities' &>>$LOG_FILE
if [ $? -ne 0 ]; then
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/schema.sql &>>$LOG_FILE
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/app-user.sql  &>>$LOG_FILE
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/master-data.sql &>>$LOG_FILE
else
    echo -e "Shipping data is already loaded ... $Y SKIPPING $N"
fi

systemctl restart shipping
VALIDATE $? "restart shipping"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME))
echo -e "script executed in:$Y  $TOTAL_TIME seconds $N"