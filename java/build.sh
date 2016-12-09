#!/bin/bash
javac -classpath ../googlesearch/lib/webmasters/*:\
../googlesearch/lib/webmasters/libs/* \
-d ./ \
RequestInitializerWrapper.java
jar cvf ../googlesearch/lib/RequestInitializerWrapper.jar com/google/api/client/http/RequestInitializerWrapper.class
rm -r ./com
