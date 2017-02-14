class Processor
	def self.processing
		puts
		print "Processing..."

		i = 0
		while i < 10
		    print "."
		    sleep(0.25)
		    i += 1
		end

		sleep(2)
		print "   Processed."
		puts
	end
end