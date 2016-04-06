#!/bin/bash
#####################################################################
# Federico F. & Priyanka K. , March 2016                            #
# Cloud Computing Coursework                                        #
#####################################################################
#trapping exit from called functions
trap "exit 1" TERM
#This line exports the current PID in a variable, this way I can kill the current process in a nested function
export TOP_PID=$$
# Enabling simple log management
export ERROR_LOG=error.log
exec 2>>${ERROR_LOG}
echo "========================================================" > ${ERROR_LOG}
echo " beginning of the error log at, start time" >> ${ERROR_LOG}
date  >> ${ERROR_LOG}
#########################################################################
#enabling colors management, we love <3 colors
function fPrintNotification {
	# Text line color constants
	lineColor='\e[1;31m'          # Light red color
	notificationColor='\e[1;32m'  # Light green color
	line="${lineColor}----------------------------------------------------------------------------------"
	echo -e ${line}
	#echo -e "| ${notificationColor} $1"
	printf "|${notificationColor} %-40s${lineColor}|\n" "$1"
	echo -e ${line}
	tput sgr0 # Reset attributes
}
#########################################################################
# Creating all the needed folders
rm -Rf workingdircloudcw
mkdir -p workingdircloudcw
#########################################################################
#variables definition, could be overwritten


########################################################################
#logic 1st part, workload choice
########################################################################
fPrintNotification " -- Welcome to the cloud computing coursework script --"
echo
echo
########################################################################
# checking for needed software installation
# trying to be portable bash 4+
hash terraform 2>/dev/null || { echo "I require terraform but it's not installed.Can you install it ?"; exit 1; }

hash curl 2>/dev/null || { echo "I require curl but it's not installed.Can you install it ?"; exit 1; }
########################################################################
echo
echo "This script is for the Cloud Computing module, is a proof of concept of a PaaS to run simple"
echo "Spark workloads on a on-demand infrastructure offered by AWS and Azure"
echo
echo
echo " The script will collect the results of the workload from S3 and destroy the infrastructure once it has finished. "
echo
echo
echo
echo " -- We're going to run a simple Spark workload --"
echo
echo
echo
fPrintNotification " -- Which example workload do you want to run ? --"

echo
echo "1) CPU "
echo "2) IO "

	read -n1 -p " > " CHOICE
	if [ $CHOICE == "1" ]; then
 		WORKLOAD=SparkcpuJobs-1.0.jar
	fi
	if [ $CHOICE == "2" ]; then
		WORKLOAD=SparkiopsJobs-1.0.jar
	fi

if [ ! -f ${WORKLOAD}  ]; then
  echo "File not available, aborting..."
  echo
  exit 1
	fi
  # insert here  first file name



########################################################################
#logic 2nd part, workload flagging
########################################################################

if [[ $WORKLOAD == *"cpu"* ]]; then
  echo
  echo "It looks like it's a CPU bound job"
  echo "I'll deploy the infrastructure on AZURE on a A10 machine"
  echo "It is priced at  $ 0.78 per hour in the US-EAST region"
  echo "This VM has 8 cores on a Intel Xeon E5-2670 @ 2.6 GHz , 56 GB of RAM  and 382 GB of standard drive at 500 IOPS"
CLOUD=AZURE
fi

if [[ $WORKLOAD == *"iops"* ]]; then
  echo
  echo "It looks like it's a I/O bound job"
  echo "I'll deploy the infrastructure on AWS on A  i2.xlarge machine"
  echo "It is priced at $ 0.853 per Hour in the US-EAST region"
  echo "This VM has 4 cores,  14 ECU of compute power (not a lot), 30.5 GB of RAM and 800 GB of SSD drive at 35.000 IOPS"
CLOUD=AWS
fi

########################################################################
#logic 4th part, setting up the working dir
########################################################################
#clearing stdin before reading
echo
echo
echo " Press return to continue..."
read -n 10000 discard

cp -R resources workingdircloudcw/
cp ${WORKLOAD} workingdircloudcw/resources/workload.jar

echo $CLOUD

if [[ $CLOUD == "AZURE" ]];   then
	cp keys.tf workingdircloudcw/
	cp bucket.tf workingdircloudcw/
	cp freetrial.publishsettings workingdircloudcw/
	cp azure.tf workingdircloudcw/
	sed -i -e 's/REPLACEME/cpu/' workingdircloudcw/resources/docker.sh
	sed -i -e 's/SPARK_WORKER_CORES.*$/SPARK_WORKER_CORES: 6/' workingdircloudcw/resources/docker-compose.yml
	sed -i -e 's/SPARK_WORKER_MEMORY.*$/SPARK_WORKER_MEMORY: 30g/' workingdircloudcw/resources/docker-compose.yml	
  if [ ! -f workingdircloudcw/freetrial.publishsettings ]; then
    echo " AZURE publishsettings files is missing, I can't procede please supply the keys.tf file"
    exit 1
	fi
fi

if [[ $CLOUD == "AWS" ]]; then
	cp bucket.tf workingdircloudcw/
	cp keys.tf workingdircloudcw/
  cp aws.tf workingdircloudcw/
	sed -i -e 's/REPLACEME/iops/' workingdircloudcw/resources/docker.sh
	sed -i -e 's/SPARK_WORKER_CORES.*$/SPARK_WORKER_CORES: 3/' workingdircloudcw/resources/docker-compose.yml
	sed -i -e 's/SPARK_WORKER_MEMORY.*$/SPARK_WORKER_MEMORY: 5g/' workingdircloudcw/resources/docker-compose.yml

  if [ ! -f workingdircloudcw/keys.tf ]; then
    echo " AWS keys files are missing, I can't procede please supply the keys.tf file"
    exit 1
	fi
fi

#clearing stdin before reading
read -t 1 -n 10000 discard


########################################################################
#logic 5th part, deploying the infrastructure
########################################################################
echo
echo
fPrintNotification " The Infrastructure is being deployed,expect VERBOSE output"
sleep 5s
cd workingdircloudcw
terraform apply

printf "\n\n\n\n\n\n"
fPrintNotification " check in the output above the address of the Spark machine that is running the workload"
printf "\n\n\n"
echo "NOTE : connect to port 8080 to reach the webUI"
echo
echo "NOTE: It is not reachable from EDUROAM network, as its firewall blocks the outgoing connections"

########################################################################
#logic 6th part, getting the results
########################################################################

if [[ $WORKLOAD == *"iops"* ]]; then

	printf "\n\n\n\n\n\n"
	echo " I'm waiting for the results to be uploaded, this can take a while "

	CURLRESULTS=`curl -Is https://s3.amazonaws.com/sparkresults/results.txt | head -n 1 | cut -d " " -f2`
	until [ ${CURLRESULTS} == "200" ]
	do
		sleep 20s
		CURLRESULTS=`curl -Is https://s3.amazonaws.com/sparkresults/results.txt | head -n 1 | cut -d " " -f2`
	done
	curl -s -o "../results.txt"  https://s3.amazonaws.com/sparkresults/results.txt
	echo
	echo
	echo
	echo " The results file has been downloaded, check it with your favourite reader, it is results.txt"
	echo " Press return to continue..."
	read -n 10000 discard
fi

########################################################################
#logic 7th part, destroying the infrastructure
########################################################################
printf "\n\n\n\n\n\n"
fPrintNotification " The IaaS has finished its job, do you want to destroy it ? y/n "
read -n2 -p "  > " DESTROY
if [ "$DESTROY" == "y" ];  then
	printf "\n\n\n"
  echo " Terraform destruction is about to start, expect verbose output"
  sleep 5s
	printf "\n\n\n"
  terraform destroy
fi
echo.
echo.
echo.
echo.
fPrintNotification " This simple script has finished.
