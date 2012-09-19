bioruby-grid
============

Utility to create and distribute jobs

Usage
=====

This utility is a command line based tool built around the concept of a template that can be reused to generate tens, hundreds or thousands of different jobs to be sent on a queue system.

It is particularly useful when dealing with BigData analysis (e.g. NGS data processing) on a distributed system.

The tool for now supports only PBS queue systems, but can be easily expanded to account also for other queueing systems.

A typical example 
=================

Let's say I have a bunch of FastQ files that I want to analyze using my favorite reads mapping tool. These files come from a typical Illumina paired end sequencing and I have 60 files from the read 1 and another 60 files from the read 2. Given that I have a distributed system I want to spread the alignments on the cluster (or grid), to speed up the analysis as much as possible. 

Instead of having to manually create a number of running scripts or rewrite for every analysis a new script to do this work, BioGrid can help you saving time handling all of this.

```shell
	bio-grid -i "/data/Project_X/Sample_Y/*_R1_*.fastq.gz","/data/Project_X/Sample_Y/*_R2_*.fastq.gz" -n bowtie_mapping -c "/software/bowtie2 -x /genomes/genome_index -p 8 -1 <input1> -2 <input2> > <output>.sam" -o /data/Project_X/Sample_Y_mapping -s 1 -p 8	
```

What is happening here is the following:

* the "-i" options specifies the input files or, as in this case, the location where to find input files based on a typical wildcard expression. You can actually specify as many input files/locations as you need using a comma separated list.
* the "-n" specify the job name
* the "-c" is the command line to be executed on the cluster / grid system. What BioGrid does is to fill in the 
```
<input1>,<input2> and <output>
``` placeholders with the corresponding parameters passed on the command lines. This is done for each input file and BioGrid will generate a unique output file name for each job.

* the "-o" just specify the location where output files for each job will be saved
* the "-s" is a key parameter to specify the number of input files (or group of files when more than one input is present in the command line) to be used for each job. So, going back to the FastQ example, if -s 1 is specified, each job will be run with exactly one FastQ R1 file and one FastQ R2 file. This gives you a great power to decide how to split the entire dataset analysis across multiple computing nodes.
* the "-p" parameter indicates how many processes we want to use for each job. This number needs to match with the actual number of threads / processes that our command or tool will use for the analysis.

All of this is just turned into a submission script that will look like this:

```shell
#!/bin/bash
#PBS -N bowtie_mapping
#PBS -l ncpus=8

mkdir -p /data/Project_X/Sample_Y_mapping
/software/bowtie2 -x /genomes/genome_index -p 8 -1 /data/Project_X/Sample_Y/Sample_Y_L001_R1_001.fastq.gz -2 Sample_Y_L001_R2_001.fastq.gz > /data/Project_X/Sample_Y_mapping/bowtie_mapping-output_001.sam
```

and this will be repeated for every input file, according to the -s parameter. So, in this case given that we have 2 input files for each command line and that we had 60 R1 and 60 R2 FastQ files and we have specified "-s 1", 60 different jobs will be created and submitted, each with a specific read pair to be processed by Bowtie.

Others options are possible at the moment, for example:

* "-t" to execute only a single job, which is useful to test parameters
* "-r" to specify a different location from the one of "-o" where to copy job output once terminated
* "-e" to erease output files once a job is completed (useful in conjuction with -r to delete local data on a computing node)
* "-d" for a dry run, to create submissions scripts without sending them in the queue system

A submission script generate using the following BioGrid command line

```shell
bio-grid -i "/data/Project_X/Sample_Y/*_R1_*.fastq.gz","/data/Project_X/Sample_Y/*_R2_*.fastq.gz" -n bowtie_apping -c "/software/bowtie2 -x /genomes/genome_index -p 8 -1 <input1> -2 <input2> > <output>.sam" -o /data/Project_X/Sample_Y_mapping -s 1 -p 8 -r /results/Sample_Y_mapping -e
```

will be turned into the following submission script:

```shell
#!/bin/bash
#PBS -N bowtie_mapping
#PBS -l ncpus=8

mkdir -p /data/Project_X/Sample_Y_mapping # output dir
/software/bowtie2 -x /genomes/genome_index -p 8 -1 /data/Project_X/Sample_Y/Sample_Y_L001_R1_001.fastq.gz -2 Sample_Y_L001_R2_001.fastq.gz > /data/Project_X/Sample_Y_mapping/bowtie_mapping-output_001.sam # command line
mkdir -p /results/Sample_Y_mapping # final location where to copy job output once terminated
cp /data/Project_X/Sample_Y_mapping/bowtie_mapping-output_001.sam /results/Sample_Y_mapping # copy of the outputs to the final location
rm -f /data/Project_X/Sample_Y_mapping/bowtie_mapping-output_001.sam # deleting output data
```

For a complete list of current BioGrid parameters, type "bio-grid -h":

```shell
    -n, --name NAME                  Analysis name
    -s, --split-number NUMBER        Number of input files (or group of files) to use per job
    -p, --processes PROCESSES        Number of processes per job
    -c, --command-line COMMANDLINE   Command line to be executed
    -o, --output OUTPUT              Output folder
    -r, --copy-to LOCATION           Copy the output once a job is terminated
    -e, --erease-output              Delete job output data when completed (useful to delete output temporary files on a computing node)
    -d, --dry                        Dry run. Just write the job scripts without sending them in queue (for debugging or testing)
    -t, --test                       Start the mapping only with the first group of reads (e.g. for testing parameters)
    -i, --input INPUT1,INPUT2...     Location where to find input files (accepts wildecards). You can specify more than one input location, just provide a comma separated list
    -h, --help                       Display this screen
```

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

