#!/bin/bash

data=$1

for var in 1 2 3 4 5 6 7 8 11 12 13 14 15 16 17 18 19
do
   gcloud compute scp ${data} wmbio${var}:/home/wmbio/
done

