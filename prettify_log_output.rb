class PrettifyLogOutput

	def start
		'PROCESSING: ' + Time.now.to_s[0..18]
	end

	def new_line
		"\n"
	end

	def end
		'PROCESSED: ' + Time.now.to_s[0..18]
	end
end