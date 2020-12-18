#!/bin/bash
# jbenninghoff 2013-Sep-13  vi: set ai et sw=3 tabstop=3:

# MapR DB tests below assume /tables volume exists and mapping in core-site.xml is configured
#maprcli volume create -name tables -path /tables -topology /data/default-rack -replication 3 -replicationtype low_latency 
#hadoop mfs -setcompression off /tables
#echo '<property> <name>hbase.table.namespace.mappings</name> <value>*:/tables</value> </property>' >> /opt/mapr/hadoop.../conf/core-site.xml
# Apache HBase will be used if core-site.xml mappings do not exist and $table set to just TestTable
table=/tables/TestTable #table name used by PerformanceEvaluation object

# HBase bundled performance tool, multithreaded
# Integer arg is number of Java threads or mapreduce processes
# Each thread writes and then reads 1M 1K-byte rows (1GB)
thrds=4
/usr/bin/time hbase org.apache.hadoop.hbase.PerformanceEvaluation --table=$table --nomapred sequentialWrite $thrds |& tee hbasePerfEvalSeqWrite-${thrds}T.log
/usr/bin/time hbase org.apache.hadoop.hbase.PerformanceEvaluation --table=$table --nomapred randomWrite $thrds |& tee hbasePerfEvalRanWrite-${thrds}T.log
/usr/bin/time hbase org.apache.hadoop.hbase.PerformanceEvaluation --table=$table --nomapred sequentialRead $thrds |& tee hbasePerfEvalSeqRead-${thrds}T.log
/usr/bin/time hbase org.apache.hadoop.hbase.PerformanceEvaluation --table=$table --nomapred randomRead $thrds |& tee hbasePerfEvalRanRead-${thrds}T.log

# mapreduce clients (use processes across the cluster instead of threads on a client machine)
#/usr/bin/time hbase org.apache.hadoop.hbase.PerformanceEvaluation sequentialWrite 20 |& tee hbasePerfEvalSeqWrite20P.log
#/usr/bin/time hbase org.apache.hadoop.hbase.PerformanceEvaluation randomWrite 20 |& tee hbasePerfEvalRanWrite20P.log
#/usr/bin/time hbase org.apache.hadoop.hbase.PerformanceEvaluation sequentialRead 20 |& tee hbasePerfEvalSeqRead20P.log
#/usr/bin/time hbase org.apache.hadoop.hbase.PerformanceEvaluation randomRead 20 |& tee hbasePerfEvalRanRead20P.log

# Very time consuming tests:
#/usr/bin/time hbase org.apache.hadoop.hbase.PerformanceEvaluation --nomapred randomSeekScan 4 |& tee hbasePerfEvalRanSeekScan.log
#/usr/bin/time hbase org.apache.hadoop.hbase.PerformanceEvaluation randomSeekScan 20 |& tee hbasePerfEvalRanSeekScan20P.log
#/usr/bin/time hbase org.apache.hadoop.hbase.PerformanceEvaluation --nomapred scanRange1000 4 |& tee hbasePerfEvalScanRange1K.log
#/usr/bin/time hbase org.apache.hadoop.hbase.PerformanceEvaluation scanRange1000 20 |& tee hbasePerfEvalScanRange1K20P.log

# What does the table look like:
hbase shell <<< "scan '$table', {LIMIT=>20}"

columns=$(stty -a | awk '/columns/{printf "%d\n",$7}')
# How did the regions get distributed across the cluster nodes:
/opt/mapr/bin/maprcli table region list -path $table | cut -c -$columns
# How did the regions get distributed across the storage pools:
#./regionsp.py $table

echo Get Throughput: grep '[0-9.]* MB/s' hbasePerfEval\*.log
