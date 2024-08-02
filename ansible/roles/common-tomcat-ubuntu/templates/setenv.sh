#!/bin/sh

export PERL5LIB=/opt/Apollo-{{apollo_build_version}}/extlib/lib/perl5:$PERL5LIB
export CATALINA_OPTS="{{apollo_tomcat_memory_opts}}"
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64

