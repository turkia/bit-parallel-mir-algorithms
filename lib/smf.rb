# encoding: utf-8
# Converts a MIDI file to a chord file used by midisearch. 
# Based on SMF library by Tadayoshi Funaba. 
#
# * http://www.funaba.org/en/music.html
# * http://www.funaba.org/en/smf/manual.html
#
# Version 0.12
# July 5th, 2002/August 9th, 2012
# Mika Turkia, turkia at cs helsinki fi

require 'smf'
include SMF

module SMF

NoteStruct = Struct.new("NoteStruct", :strt, :dur, :ptch)

class Sequence

	class MIDI2Chords < XSCallback

		def header(format, ntrks, division, tc = nil)
			@notes_on = {}
			@tracks = []
			@currenttrack = -1
			@s = format("Sequence %d %d %d\n", format, ntrks, division)
		end

		def track_start()
			@offset = 0
			@currenttrack += 1
			@tracks[@currenttrack] = []
		end

		def delta(delta)
			@offset += delta
		end

		def noteoff(ch, note, vel)
			strt = @notes_on.fetch([ch, note])
			@tracks[@currenttrack].push(NoteStruct.new(strt, @offset - strt, note))
		end

		def noteon(ch, note, vel)
			if vel == 0 then noteoff(ch, note, vel)
			else @notes_on.store([ch, note], @offset) end
		end

		def result()
			notes = []
			@tracks.each do |track| notes += track end
			notes.sort! { |a, b| a.strt <=> b.strt }
			make_chords(notes)
		end

		def make_chords(notes)
			j = 0
			chords = []
			strt = notes[0].strt
			chords[j] = [ notes[0].ptch ]

			for i in 1...notes.size do
				if notes[i].strt == strt then
					chords[j] += [ notes[i].ptch ]
				else
					chords[j].sort!
					j += 1 
					strt = notes[i].strt
					chords[j] = [ notes[i].ptch ]
				end
			end
			chords
		end
	end

	def convert
		WS.new(self, MIDI2Chords.new).read
	end
end

end # module SMF
