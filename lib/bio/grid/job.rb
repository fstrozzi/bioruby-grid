module Bio
	class Grid
		class Job
			
			attr_accessor :options, :instructions, :job_output, :runner, :uuid
			def initialize(options)
				@options = options
				self.instructions = []
			end

			def	set_output_dir
				output_dir = (self.options[:output_folder]) ? "mkdir -p #{self.job_output}\ncd #{self.job_output}\n" : "mkdir -p #{self.options[:output]}\n"
				self.instructions.insert(1,output_dir)
			end

			def set_commandline(cmd_line,inputs,input1,groups,index)	
				commandline = cmd_line.gsub(/<input1>|<input>/,input1.join(self.options[:sep]))
				inputs.each do |input|
					commandline.gsub!(/<#{input}>/,groups[input][index].join(self.options[:sep]))
				end
				job_output = self.options[:output]+"/#{options[:uuid]}_"+self.options[:name]+"_%03d" % (index+1).to_s + "#{self.options[:parameter_value]}"
				if commandline =~/<output>\.(\S+)/
					extension = $1
					commandline.gsub!(/<output>/,job_output)	
					job_output << ".#{extension}"
				else
					self.options[:output_folder] = true
					commandline.gsub!(/<output>/,job_output)
				end
				self.instructions << commandline+"\n"
				self.job_output = job_output
			end

			def append_options
				if self.options[:copy]
					self.instructions << ("mkdir -p #{self.options[:copy]}\n")
					copy_type = (self.options[:output_folder]) ? "cp -r" : "cp"
					self.instructions << ("#{copy_type} #{self.job_output} #{self.options[:copy]}\n")
				end

				if self.options[:clean]
					rm_type = (self.options[:output_folder]) ? "rm -fr" : "rm -f"
					self.instructions << ("#{rm_type} #{self.job_output}\n")
				end	
			end

			def write_runner(filename)
				self.runner = filename
				out = File.open(Dir.pwd+"/"+filename,"w")
				out.write(self.instructions.join+"\n")
				out.close
			end

			def run(filename)
				self.write_runner(filename)
				system("qsub #{self.runner}") unless self.options[:dry]
			end

			def set_scheduler_options(type)
				self.instructions << "#!/bin/bash\n#PBS -N #{self.options[:name]}\n#PBS -l ncpus=#{self.options[:processes]}\n\n" if type == :pbs
			end

			def	execute(command_line,inputs,input1,groups,index)
				self.set_scheduler_options(:pbs) # set script specific options for the scheduling system
        self.set_commandline(command_line,inputs,input1,groups,index)
				self.set_output_dir
        self.append_options
        job_filename = (self.options[:keep]) ? "job_#{index+1}#{self.options[:parameter_value]}.sh" : "job.sh"
        self.run(job_filename)
			end


		end
	end
end
