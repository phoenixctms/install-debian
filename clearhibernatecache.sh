#!/bin/bash
curl --request POST http://127.0.0.1:8080/rest/tools/clearresourcebundlecache
curl --request POST http://127.0.0.1:8080/rest/tools/clearhibernatecache
curl --request POST http://127.0.0.1:8080/rest/tools/cleanjavaclasses