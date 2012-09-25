module Bio
	
	class Grid
	
		attr_accessor :input,:number,:uuid
		def initialize(input,number)
			@input = input
			@number = number
			@uuid = UUID.new.generate.split("-").first
		end

		def self.run(options)
			options[:number] = "all" unless options[:number]
			grid = self.new options[:input], options[:number]
			options[:uuid] = grid.uuid
			groups = grid.prepare_input_groups
			inputs = groups.keys.sort
			groups[inputs.shift].each_with_index do |input1,index|
				if options[:cmd]=~/<(\d+),(\d+)(,\d+)*>/
					step = ($3) ? $3.tr(",","").to_i : 1
					range = Range.new($1.to_i,$2.to_i,false).step(step).to_a
					range.each do |value|
						cmd_line = options[:cmd].gsub(/<(\d+),(\d+)(,\d+)*>/,value.to_s)
						job = Bio::Grid::Job.new(options) # inherit global options
						job.options[:parameter_value] = "-param:#{value}"
						job.execute(cmd_line,inputs,input1,groups,index)
					end
				elsif options[:params]
					options[:params].each do |p|
						cmd_line = options[:cmd].gsub(/<param>|<parameter>/,p)
						job = Bio::Grid::Job.new(options)
						job.options[:parameter_value] = "-param:#{p}"
						job.execute(cmd_line,inputs,input1,groups,index)
					end
				else
					job = Bio::Grid::Job.new(options) # inherit global options
					job.execute(options[:cmd],inputs,input1,groups,index)
				end

				break if options[:test]
			end			
		end

		def	prepare_input_groups
			groups = Hash.new {|h,k| h[k] = [] }
			self.input.each_with_index do |location,index|
				list = Dir.glob(location).sort
				raise ArgumentError,"Input file or folder #{location} do not exist!" if list.empty?
				if self.number == "all"
					groups["input#{index+1}"] = [list]
				else
					list.each_slice(self.number.to_i) {|subgroup| groups["input#{index+1}"] << subgroup}
				end
			end
			groups
		end

	end

end
