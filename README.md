# DataFibers Demo Projects
[![Gitter](https://badges.gitter.im/datafibers/df.svg)](https://gitter.im/datafibers/df?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge) [![Build Status](https://travis-ci.org/datafibers/df.svg?branch=master)](https://travis-ci.org/datafibers/df)

##1. Overview
This is where we demo projects using DF. There are following projects in pipeline
- [x] DF ingests data => Kafka => ElasticSearch => Grafna
- [ ] DF ingests data => PostgreSQL => Zeppelin
- [ ] DF ingests data => Kafka => Flink|Spark => Zeppelin
- [ ] DF ingests data => Kafka => Flink|Spark => ElasticSearch => Zeppelin
- [ ] DF ingests data => Hive | HBase => Flink|Spark => Zeppelin
- [ ] DF ingests data => Hive | HBase => Zeppelin
- [ ] DF ingests data => D3

##2. VM Setup
The [installvm.sh](https://github.com/datafibers/df_demo/blob/master/df-environment/df-env-vagrant/installvm.sh) is used to generate different profiles for VM setup used by Vagrant. 

* In Linux, you can either run in in Linux directly. 
* In Windows, run it through [Git for Windows](https://git-for-windows.github.io/)'s GitBash

##3. Demo Setup
Run [run_demo.sh](https://github.com/datafibers/df_demo/blob/master/df-environment/df-env-app-init/run_demo.sh) to start all deamons for demo.

