#Name: bootstrapping script for Cloud Computing coursework
#Author: Federico Fregosi, March 2016
#Version: 1.1

#curl prerequisite for Docker
sudo apt-get -y install curl
sudo apt-get update
#docker
#make sure the current user can sudo pwdless
sudo curl -sSL https://get.docker.com/ | sh
sudo apt-get install docker-engine
sudo service docker start
sudo apt-get -y install python-pip
sudo pip install docker-compose
#pulling images
sudo docker pull sorcerer01/master
sudo docker pull sorcerer01/worker
#starting compose
sudo docker-compose -f /tmp/docker-compose.yml up &
#avoiding annoying timeout
sleep 60s
#starting services on master
sudo docker exec master service collectd start
sudo docker exec master service spm-sender start
sudo docker exec master hadoop fs -copyFromLocal /tmp/data .
#starting services on worker
sudo docker exec worker service collectd start
sudo docker exec worker service spm-sender start
#WORKLOAD VARIABLE TO BE REPLACED BY MAIN SCRIPT
WORKLOAD=REPLACEME

if [ ${WORKLOAD} = "iops" ]; then
sudo docker exec master hadoop fs -copyFromLocal /tmp/data .
sudo docker exec master spark-submit --verbose  --class app.spark.io.WordCountHDFSIO /tmp/data/workload.jar /tmp/data/shakespeare.txt /tmp/data/WordCountHDFS
sleep 10
sudo docker exec master spark-submit --verbose  --class app.spark.io.JavaALSIO /tmp/data/workload.jar /tmp/data/ratings_rf.txt /tmp/data/JavaALS 2 5 5
sleep 10
sudo docker exec master spark-submit --verbose  --class app.spark.io.JavaLogQueryIO /tmp/data/workload.jar /tmp/data/access_logs.txt /tmp/data/JavaLogQuery

sudo pip install s3cmd
s3cmd --access_key=XXXXXXXXXXXXXXX --secret_key=XXXXXXXXXXXXXX put /tmp/JavaLogQuery/JavaLogQuery/results.txt s3://sparkresults

fi
if [ ${WORKLOAD} = "cpu" ]; then
  mkdir -p /tmp/data/WordCountHDFS
sudo docker exec master spark-submit --verbose  --class app.spark.cpu.WordCountHDFS /tmp/data/workload.jar /tmp/data/shakespeare.txt  /tmp/data/WordCountHDFS
  sleep 10;
  mkdir -p /tmp/data/WordCountHDFS
sudo docker exec master spark-submit --verbose  --class app.spark.cpu.SparkPi /tmp/data/workload.jar 3 /tmp/data//SparkPi
  sleep 10
  mkdir -p /tmp/data/JavaALS
sudo docker exec master spark-submit --verbose  --class app.spark.cpu.JavaALS /tmp/data/workload.jar /tmp/data/ratings_rf.txt /tmp/data/JavaALS 2 5 5
  sleep 10
  mkdir -p /tmp/data/JavaLogQuery
sudo docker exec master spark-submit --verbose  --class app.spark.cpu.JavaLogQuery /tmp/data/workload.jar /tmp/data/access_logs.txt /tmp/data/JavaLogQuery
fi
