# iPerfGrapher
Plot results from iPerf tests using Gnuplot.

Does not support iPerf 3. The command needs to have the --reportstyle C flag, as this script reads the CSV output of the command and extract the throughput statistics.

Sample iPerf command that can be assigned as a string to the iperfCommand variable:

```
iperf -c <server> -i <interval> --reportstyle C -P <parallel>
```

The appearance of the plot can be changed by modifying the plotData() method. Refer to the Gnuplot RUBY gem documentation for more info.
