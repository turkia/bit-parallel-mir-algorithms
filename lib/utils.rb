# encoding: utf-8

require_relative 'smf'
require_relative 'bpmir'

# Utilities for handling MIDI files. 
class BPMIR::MidiUtil
 
	RE = /.mid$/

	# Converts all MIDI files in a directory to chords files, and also creates a preprocessed data format for MonoPoly algorithm. 
	def self.convert(sourcedir, targetdir)
		path = targetdir + File::SEPARATOR
		Dir.foreach(sourcedir) do |entry|
			if entry.match(RE) then
				chords = SMF::Sequence.decodefile(sourcedir + File::SEPARATOR + entry).convert
				self.save(chords, path + entry.gsub(RE, '.chords'))
				self.save(BPMIR::monopoly_preprocess(chords), path + entry.gsub(RE, '.pp'))
			end
		end
	end

	# Loads a file into memory. 
	def self.load(filename)
		File.open(filename, "r") do |file| Marshal.load(file) end
	end

	# Saves chords or preprocessed data to a file. 
	def self.save(data, filename)
		File.open(filename, "w") do |file| Marshal.dump(data, file) end
	end

	# Prints chords. 
	def self.print_chords(chords)
		chords.each do |chord|
			chord.each do |pitch| print "#{pitch.to_s} " end
			puts
		end
		puts
	end
end
