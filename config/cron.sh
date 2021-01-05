#!/bin/sh

echo "Early Entry"

cleanup ()                                                                 
{                                                                          
  kill -s SIGTERM $!                                                         
  exit 0                                                                     
}                                                                          
                                                                           
trap cleanup SIGINT SIGTERM                                                
                       
while : 
do 
	sleep 60 ; cd /var/www/app/ && php artisan schedule:run; 
done
