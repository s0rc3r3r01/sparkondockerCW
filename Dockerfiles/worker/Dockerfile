# This is a comment
FROM gettyimages/spark
MAINTAINER s0rc3r3r01 <>
RUN apt-get update
# Order CANNOT BE CHANGED as wget needs to be installed before the rest
RUN apt-get install -y collectd wget
# Installing sematext
RUN wget -O - https://pub-repo.sematext.com/debian/sematext.gpg.key | apt-key add -
RUN /etc/init.d/collectd restart
RUN echo "deb http://pub-repo.sematext.com/debian sematext main" >> /etc/apt/sources.list
RUN apt-get update
RUN apt-get install -y spm-client
#configuring sematext
RUN bash /opt/spm/bin/spm-client-setup-conf.sh 05710228-8575-463a-bc98-0a6e0ba14d8f spark javaagent spark-worker
RUN bash /opt/spm/bin/spm-client-setup-conf.sh 05710228-8575-463a-bc98-0a6e0ba14d8f spark javaagent spark-executor
RUN echo "*.sink.jmx.class=org.apache.spark.metrics.sink.JmxSink" >> /usr/spark-1.6.1/conf/metrics.properties
RUN echo "worker.source.jvm.class=org.apache.spark.metrics.source.JvmSource"  >> /usr/spark-1.6.1/conf/metrics.properties
RUN echo "executor.source.jvm.class=org.apache.spark.metrics.source.JvmSource"  >> /usr/spark-1.6.1/conf/metrics.properties
RUN echo "export SPARK_WORKER_OPTS=\"$SPARK_WORKER_OPTS-Dcom.sun.management.jmxremote -javaagent:/opt/spm/spm-monitor/lib/spm-monitor-spark.jar=05710228-8575-463a-bc98-0a6e0ba14d8f:spark-worker:default\"" >> /usr/spark-1.6.1/conf/spark-env.sh
RUN echo "spark.executor.extraJavaOptions -Dcom.sun.management.jmxremote -javaagent:/opt/spm/spm-monitor/lib/spm-monitor-spark.jar=05710228-8575-463a-bc98-0a6e0ba14d8f:spark-executor:default" >> /usr/spark-1.6.1/conf/spark-defaults.conf
RUN echo "spark.eventLog.enabled true" >> /usr/spark-1.6.1/conf/spark-defaults.conf
RUN echo "spark.eventLog.dir file:///tmp/spark-events" >> /usr/spark-1.6.1/conf/spark-defaults.conf
RUN mkdir -p /tmp/spark-events
RUN chmod 777 /tmp/spark-events
