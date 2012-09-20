bioruby-grid
============

Utility to create and distribute jobs on a queue system. It is particularly suited to process BigData (i.e. NGS analyses), helping generating hundreds of different jobs with ease to crunch large datasets.

Usage
=====

This utility is a command line based tool built around the concept of a template that can be reused to generate tens, hundreds or thousands of different jobs to be sent on a queue system.

The tool for now supports only PBS queue systems, but can be easily expanded to account also for other queueing systems.

A typical example 
-----------------

Let's say I have a bunch of FastQ files that I want to analyze using my favorite reads mapping tool. These files come from a typical Illumina paired end sequencing and I have 60 files from the read 1 and another 60 files from the read 2. Given that I have a distributed system I want to spread the alignments on the cluster (or grid), to speed up the analysis as much as possible. 

Instead of having to manually create a number of running scripts or rewrite for every analysis a new script to do this work, BioGrid can help you saving time handling all of this.

```shell
	bio-grid -i "/data/Project_X/Sample_Y/*_R1_*.fastq.gz","/data/Project_X/Sample_Y/*_R2_*.fastq.gz" -n bowtie_mapping -c "/software/bowtie2 -x /genomes/genome_index -p 8 -1 <input1> -2 <input2> > <output>.sam" -o /data/Project_X/Sample_Y_mapping -s 1 -p 8	
```

What is happening here is the following:

* the ```-i``` options specifies the input files or, as in this case, the location where to find input files based on a typical wildcard expression. You can actually specify as many input files/locations as you need using a comma separated list.
* the ```-n``` specify the job name
* the ```-c``` is the command line to be executed on the cluster / grid system. What BioGrid does is to fill in the ```<input1>```,```<input2>``` and ```<output>``` placeholders with the corresponding parameters passed on the command line. This is done for each input file (or each group of input files) and BioGrid will check if the ```<output>``` placeholder has an extension (like .sam, .out etc.) and will generate a unique output file name for each job. IMPORTANT: If no extension is specified for the ```<output>``` placeholder, BioGrid will assume the job will generate more than one output files and that those files will be saved into the folder specified by the "-o" option. Therefore it will manage the output as a whole directory, copying and/or removing the entire folder if "-r" and "-e" options are present (check the [Other options](https://github.com/fstrozzi/bioruby-grid#other-options) section to see what these options are expected to do).


* the ```-o``` set the location where output files for each job will be saved. Only provide the folder where you want to save the output file(s), BioGrid will take care of generating a unique file name for the output, if needed.
* the ```-s``` is a key parameter to specify the granularity of the jobs, setting the number of input files (or group of files, when more than one input placeholder is present in the command line) to be used for each job. So, going back to the FastQ example, if -s 1 is specified, each job will be run with exactly one FastQ R1 file and one FastQ R2 file. This gives you a great power in deciding how to split the entire dataset analysis across multiple computing nodes.
* the ```-p``` parameter indicates how many processes we want to use for each job. This number needs to match with the actual number of threads / processes that our command or tool will use for the analysis.

All of this is just turned into a submission script that will look like this:

```shell
#!/bin/bash
#PBS -N bowtie_mapping
#PBS -l ncpus=8

mkdir -p /data/Project_X/Sample_Y_mapping
/software/bowtie2 -x /genomes/genome_index -p 8 -1 /data/Project_X/Sample_Y/Sample_Y_L001_R1_001.fastq.gz -2 Sample_Y_L001_R2_001.fastq.gz > /data/Project_X/Sample_Y_mapping/bowtie_mapping-output_001.sam
```

and this will be repeated for every input file, according to the -s parameter. So, in this case given that we have 2 input files for each command line and that we had 60 R1 and 60 R2 FastQ files and we have specified "-s 1", 60 different jobs will be created and submitted, each with a specific read pair to be processed by Bowtie.

Other options
-------------

With BioGrid you can specify many different tasks for the job to execute, for example:

* ```-t``` to execute only a single job, which is useful to test parameters
* ```-r``` to specify a different location from the one used in ```-o```. This folder will be used to copy job outputs once terminated
* ```-e``` to erease output files/folders specified by ```-o``` once a job is completed (useful in conjuction with ```-r``` to delete local data on a computing node)
* ```-d``` for a dry run, to create submissions scripts without sending them in the queue system

The following BioGrid command line:

```shell
bio-grid -i "/data/Project_X/Sample_Y/*_R1_*.fastq.gz","/data/Project_X/Sample_Y/*_R2_*.fastq.gz" -n bowtie_mapping -c "/software/bowtie2 -x /genomes/genome_index -p 8 -1 <input1> -2 <input2> > <output>.sam" -o /data/Project_X/Sample_Y_mapping -s 1 -p 8 -r /results/Sample_Y_mapping -e
```

will be turned into this submission script:

```shell
#!/bin/bash
#PBS -N bowtie_mapping
#PBS -l ncpus=8

mkdir -p /data/Project_X/Sample_Y_mapping # output dir
/software/bowtie2 -x /genomes/genome_index -p 8 -1 /data/Project_X/Sample_Y/Sample_Y_L001_R1_001.fastq.gz -2 Sample_Y_L001_R2_001.fastq.gz > /data/Project_X/Sample_Y_mapping/bowtie_mapping-output_001.sam # command line
mkdir -p /results/Sample_Y_mapping # final location where to copy job output once terminated
cp /data/Project_X/Sample_Y_mapping/bowtie_mapping-output_001.sam /results/Sample_Y_mapping # copy the outputs to the final location
rm -f /data/Project_X/Sample_Y_mapping/bowtie_mapping-output_001.sam # deleting output data
```

For a complete list of current BioGrid parameters, type "bio-grid -h":

```
    -n, --name NAME                  Analysis name
    -s, --split-number NUMBER        Number of input files (or group of files) to use per job. If all the files in a location need to be used for a single job, just specify 'all'
    -p, --processes PROCESSES        Number of processes per job
    -c, --command-line COMMANDLINE   Command line to be executed
    -o, --output OUTPUT              Output folder
    -r, --copy-to LOCATION           Copy the output once a job is terminated
    -e, --erease-output              Delete job output data when completed (useful to delete output temporary files on a computing node)
    -d, --dry                        Dry run. Just write the job scripts without sending them in queue (for debugging or testing)
    -t, --test                       Start the mapping only with the first group of reads (e.g. for testing parameters)
    -i, --input INPUT1,INPUT2...     Location where to find input files (accepts wildcards). You can specify more than one input location, just provide a comma separated list
        --sep SEPARATOR              Input file separator [Default: , ]
        --keep-scripts               Keep all the running scripts created for all the jobs
    -h, --help                       Display this screen
```

Advanced stuff
==============

Ok let's unleash the potential of BioGrid.
By putting together an automatic system to generate and submit jobs on a queue systems and a command line template approach, we can do some interesting things.

Parameters sampling and testing
-------------------------------

The tipical scenario is when I have to run a tool on a new dataset and I would like to test different parameters to asses which are the better ones for my analysis.
This can be easily done with BioGrid. For example:

```shell
bio-grid -i "/data/Project_X/Sample_Y/*_R1_*.fastq.gz","/data/Project_X/Sample_Y/*_R2_*.fastq.gz" -n bowtie_mapping -c "/software/bowtie2 -x /genomes/genome_index -p 8 -L <22,32,2> -1 <input1> -2 <input2> > <output>.sam" -o /data/Project_X/Sample_Y_mapping -s 1 -p 8 -r /results/Sample_Y_mapping -e -t
```

The key points here are the ```-L <22,32,2>``` in the command line template and the ```-t``` options of BioGrid. The first is a way to tell BioGrid to generate a number of similar jobs, each one with a different value for the parameter ```-L```. The values are decided based on the information passsed within the ```< >```:

* the first number is the first value that the parameter will take
* the second number is the last value that the parameter will take
* the third number is the increment to generate the range of values in between

So in this case, the ```-L``` parameter will take 6 different values: 22, 24, 26, 28, 30 and 32.

Last but not least, the ```-t``` option is essential so that only a single job per input file (or group of files) will be executed. Sampling parameters values is a typical combinatorial approach and this option avoids generating hundreds of different jobs only to sample a parameter. Coming back to the initial example, if I have 60 pairs of FastQ files, without the ```-t``` option, the job number will be 60x6 = 360, which is just crazy when you only want to test different parameter values. 

So far, BioGrid does not support sampling more than one parameter at the same time.

Contributing to bioruby-grid
============================
 
* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet.
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it.
* Fork the project.
* Start a feature/bugfix branch.
* Commit and push until you are happy with your contribution.
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

Copyright
=========

Copyright (c) 2012 Francesco Strozzi. See LICENSE.txt for
further details.

