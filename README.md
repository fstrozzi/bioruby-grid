bioruby-grid
============

Utility to create and distribute jobs

Usage
=====

This utility is command line based tools built around the concept of a command line template that can be reused to generate tens, hundreds or thousands of different jobs to be sent on a queue system.
It is particularly useful when dealing with BigData analysis (e.g. NGS data processing) on a distributed system.
The code for now supports only PBS queue systems, but can be easily expanded to account also for other queueing systems.

A typical example 
=================

Let's say I have a bunch of FastQ files that I want to analyze using my favorite reads mapping tool. These files come from a typical Illumina paired end sequencing and I have 60 files from the read 1 and another 60 files from the read 2. Given that I have a distributed system I want to spread the alignments on the cluster (or grid), to speed up the analysis as much as possible. 

Instead of having to manually create a number of running scripts or rewrite for every analysis a new script to do this work, BioGrid can help you saving time handling all of this.

```shell
	bio-grid -i "/data/Project_X/Sample_Y/*_R1_*.fastq.gz","/data/Project_X/Sample_Y/*_R2_*.fastq.gz" -n Mapping -c "/software/bowtie2 -x /genomes/genome_index -1 <input1> -2 <input2> > <output>.sam" -o /data/Project_X/Sample_Y_mapping -s 1 -p 8	
```

What is happening here is the following:

* the "-i" options specifies the input files or, as in this case, the location where to find input files based on a typical wildcard expression. You can actually specify as many input files/locations as you need using a comma separated list.
* the "-n" specify the job name
* the "-c" is the command line to be executed on the cluster / grid system. What BioGrid does is to fill in the <input1>, <input2> and <output> placeholders with the corresponding parameters passed on the command lines. This is done for each input file and BioGrid will generate a unique output file name for each job.
* the "-o" just specify the location where output files for each job will be saved
* the "-s" is a key parameter to specify the number of input files (or group files when more than one input is present in the command line) to be used for each job. So, going back to the FastQ example, if -s 1 is specified, each job will be run with exactly one FastQ R1 file and one FastQ R2 file. This gives you a great power to decide how to split the entire dataset analysis across multiple computing nodes.
* the "-p" parameter indicates how many processes we want to use for each job. This number needs to match with the actual number of threads / processes that our command or tool will use for the analysis.

All of this is just turned into a submission script that will look like this:

```shell
!/bin/bash
#PBS -N test
#PBS -l ncpus=2

mkdir -p /data/Project_X/Sample_Y_mapping
/software/bowtie2 -x /genomes/genome_index -1 /data/Project_X/Sample_Y/Sample_Y_L001_R1_001.fastq.gz -2 Sample_Y_L001_R2_001.fastq.gz > Mapping-output_001.sam
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

