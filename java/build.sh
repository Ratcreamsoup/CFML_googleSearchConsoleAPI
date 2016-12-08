#!/bin/bash
javac -classpath ../googlesearch/lib/webmasters/*:\
../googlesearch/lib/webmasters/libs/* \
-d ./ \
DisableTimeout.java
jar cvf ../googlesearch/lib/DisableTimeout.jar com/google/api/client/http/DisableTimeout.class
rm -r ./com
