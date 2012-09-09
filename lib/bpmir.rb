# encoding: utf-8

# Bit-parallel musical information retrieval algorithms.
#
# Version 0.2
# July 5th, 2002/August 9th, 2012
# Mika Turkia, turkia at cs helsinki fi
#
# * Lemström, K., Tarhio, J.: Transposition invariant pattern matching for multi-track strings. Nordic Journal of Computing, 2003. 10, 3, s. 185-205. Online at https://tuhat.halvi.helsinki.fi/portal/services/downloadRegister/14284996/03NJC_LT.pdf
# * Lemström, K.: String Matching Techniques for Music Retrieval. Department of Computer Science, Series of Publications A, Report A-2000-4. Online at http://www.cs.helsinki.fi/u/klemstro/THESIS/
class BPMIR
 
	# Machine word length (32 or 64 bits).
	WORDLENGTH = (0.size == 8 ? 64 : 32)

	# Vocabulary size, i.e. the number of notes in an octave. 
	VOCSIZE = 12

	# Helper constant: a word full of 1 bits. 
	ONES = 2 ** VOCSIZE - 1

	# The preprocessing phase of Monopoly algorithm. 
	# See Lemström 2000, pp. 40-43, and Lemström and Tarhio 2003, section 4.3.1. 
	def self.monopoly_preprocess(chords)

		s = []

		for j in 0...(chords.size - 1) do
			s[j] = ONES

			# intervals between base note of the previous chord and notes in the current chord
			# if base was chords[j].min then sorting during preprocessing is needed
			base = (chords[j])[0]
			chords[j + 1].each do |note|
				b = (note - base) % VOCSIZE
				pow = 2 ** b
				tmp = ONES - pow
				if (s[j] | tmp != tmp) then s[j] -= pow end
			end

			# shift intervals by differences between the base and other notes
			shifts = ONES
			for i in 1...chords[j].size do shifts &= rcs(s[j], VOCSIZE, ((chords[j])[i] - base) % VOCSIZE) end
			s[j] &= shifts
		end
		s
	end

	# The filtering phase of Monopoly algorithm. 
	# See Lemström 2000, pp. 40-43, and Lemström and Tarhio 2003, section 4.3.2. 
	def self.monopoly(chords, preprocessed, pattern)

		results = []
		i = []; l = []; t = []

		initial = 2 ** pattern.size - 1
		mask = initial
		e = initial - 1
		tmp = ONES
		em = tmp - 2 ** (pattern.size - 2)

		for k in 0...VOCSIZE do
			i[k] = tmp - 2 ** k
			l[k] = e
		end

		for k in 1...pattern.size do
			l[(pattern[k].ord - pattern[k - 1].ord) % VOCSIZE] -= 2 ** (k - 1)
		end

		for kk in 0...ONES do
			t[kk] = mask
			for k in 0...VOCSIZE do
				ivect = i[k]
				if (ivect | kk == ivect) then t[kk] &= l[k] end
			end
		end

		for j in 0...preprocessed.size do
			e = ((e << 1) | t[preprocessed[j]]) & mask
			if (e | em == em) then
				results << matchcheck(chords, j - pattern.size + 2, pattern)
			end
		end
		results
	end

	# MP algorithm, which is octave equivalent but not translation invariant. 
	def self.mp(chords, pattern)

		results = []
		t = []
		initial = 2 ** (pattern.size - 1) - 1
		for i in -127..127 do t[i + 127] = initial end
		for i in 1...pattern.size do t[pattern[i].ord - pattern[i - 1].ord + 127] -= 2 ** (i - 1) end

		e = initial
		mask = initial + 1
		em = 2 ** VOCSIZE - 1 - 2 ** (pattern.size - 2)
		tmp = 2 ** WORDLENGTH - 1

		for j in 1...chords.size do
			d = []

			chords[j].each do |b|
				chords[j - 1].each do |a| d |= [ b - a ]  end
			end

			d.each do |interval| tmp &= t[interval + 127] end

			e = ((e << 1) | tmp) & mask

			if (e | em == em) then
				results << matchcheck(chords, j - pattern.size + 1, pattern)
			end
		end
		results
	end

	# MP2 algorithm featuring both translation invariance and octave equivalence. 
	def self.mp2(chords, pattern)

		results = []
		t = []
		initial = 2 ** (pattern.size - 1) - 1
		for i in 0..VOCSIZE do t[i] = initial end
		for i in 1...pattern.size do t[(pattern[i].ord - pattern[i - 1 ].ord) % VOCSIZE] -= 2 ** (i - 1) end

		e = initial
		mask = initial + 1
		em = 2 ** VOCSIZE - 1 - 2 ** (pattern.size - 2)
		tmp = 2 ** WORDLENGTH - 1

		for j in 1...chords.size do
			d = []

			chords[j].each do |b|
				chords[j - 1].each do |a| d |= [ (b - a) % VOCSIZE ]  end
			end

			d.each do |interval| tmp &= t[interval] end

			e = ((e << 1) | tmp) & mask

			if (e | em == em) then
				results << matchcheck(chords, j - pattern.size + 1, pattern)
			end
		end
		results
	end

	# The ShiftOrAnd algorithm finds exact matches only, and does not report which notes inside the chords matched.
	# See Lemstrom and Tarhio 2003, section 3.1. 
	def self.shiftorand(chords, pattern)

		results = []
		t = []
		initial = 2 ** pattern.size - 1

		for i in 0..127 do t[i] = initial end
		for i in 0...pattern.size do t[pattern[i].ord] -= 2 ** i end

		mask = e = 2 ** pattern.size - 1
		tmp = 2 ** WORDLENGTH - 1
		em = tmp - 2 ** (pattern.size - 1)

		for j in 0...chords.size do
			chords[j].each do |note| tmp &= t[note] end
			e = ((e << 1) | tmp) & mask
			if (e | em == em) then
				results << { :start => j - pattern.size + 1, :end => j }
			end
		end
		results
	end

	# See Lemstrom and Tarhio 2003, section 4.1. 
	# This implementation reports also overlapping transposition invariant matches, e.g. both 65-60 and 65-72. 
	def self.directcheck(chords, pattern)

		p = BPMIR::get_pattern_intervals(pattern)
		results = []
		for j in 1..(chords.size - p.size) do

			# calculate intervals between the current note and the previous chord
			# this should be changed to the c implementation: intervals for one note only -> c = curr is simple
			chords[j].each do |curr|

				intervals = []
				matched = []
				chords[j - 1].each do |prev| intervals.push(curr - prev) end

				# process the calculated intervals
				intervals.each_with_index do |interval, ii|
					if (p[0] % VOCSIZE == interval % VOCSIZE) then
						i = 1
						jj = j + 1
						found = true
						c = curr
						matched.push(chords[j - 1][ii])
						matched.push(c)

						while found == true && i < p.size do
							x = c + p[i]
							if (chords[jj].detect {|y| y % VOCSIZE == x % VOCSIZE })
							then c = x; jj += 1; matched.push(c)
							else found = false; matched = []
							end
							i += 1
						end

						if found == true then
							results << { :start => j - 1, :end => j + pattern.size - 2, :notes => matched }
							matched = []
						end
					end
				end
			end
		end
		results
	end

	# See Lemstrom and Tarhio 2003, section 4.1. 
	# NB: s contains intervals between chords, but we need intervals between the current note and next chord only. 
	# Therefore spurious matches were not rejected. 
	# The problem has been corrected by checking that the octave equivalent note is present,
	# which affects the original time complexity.  
	def self.directcheck2(chords, preprocessed, pattern)

		results = []
		mask = 2 ** VOCSIZE - 1

		for j in 0..(preprocessed.size - pattern.size + 1) do
			matched = []
			chords[j].each do |curr|
				i = 0
				found = true
				c = curr

				matched.push(c)	
				while found == true && i < pattern.size - 1 do
					interval = pattern[i + 1].ord - pattern[i].ord
					x = c + interval 
					em = mask - 2 ** (interval % VOCSIZE)

					if (preprocessed[j + i] | em == em && y = chords[j+i+1].detect {|y| y % VOCSIZE == x % VOCSIZE } )
					then c = x; matched.push(y)
					else found = false; matched = []
					end
					i += 1
				end

				if found == true then
					results << { :start => j, :end => j + pattern.size - 1, :notes => matched }
					matched = []
				end
			end
		end
		results
	end

	private 

	# Right Circularshift Bitwise operator for MonoPoly preprocessing. 
	# See Lemström 2000, pp. 42, and Lemström and Tarhio 2003, section 4.3.1. 
	def self.rcs(value, width, amount)
		(((value << (width - amount)) & ~(~0 << width)) | ((value >> (amount)) & ~(~0 << (width - amount))))
	end

	# A match checking method for match candidates filtered by MonoPoly, MP and MP2. 
	# Since the intervals have already been checked, they need not be rechecked. 
	# This implementation does not report overlapping transposition invariant matches.
	# E.g. only one of 65-60 and 65-72 is reported. 
	def self.matchcheck(chords, j, pattern)

		results = []
		matched = []

		chords[j].each do |curr|
			i = 0
			found = true
			c = curr

			matched.push(c)	
			while found == true && i < pattern.size - 1 do
				x = c + pattern[i + 1].ord - pattern[i].ord

				if (y = chords[j+i+1].detect {|y| y % VOCSIZE == x % VOCSIZE } ) then c = x; matched.push(y)	
				else found = false; matched = []
				end
				i += 1
			end

			if found == true then
				results << { :start => j, :end => j + pattern.size - 1, :notes => matched }
				matched = []
			end
		end
		results
	end

	# Calculates intervals in the pattern for the directcheck algorithm. 
	# Pattern is a string of bytes where each byte corresponds to a pitch value. 
	def self.get_pattern_intervals(pattern)
		intervals = []
		arr = pattern.unpack('c*')
		if arr.size < 2 then return nil end

		for i in 1...arr.size do
			intervals[i - 1] = arr[i] - arr[i - 1]
		end
		intervals
	end
end
