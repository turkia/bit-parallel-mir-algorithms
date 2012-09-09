bit-parallel-mir-algorithms
===========================

Bit-parallel musical information retrieval (MIR) algorithms in pure Ruby, intended for searching melodies in MIDI data. 

The algorithms have been implemented in 2002 and updated to Ruby 1.9.3 in 2012. They are described in the following publications: 

* Lemstrom, K., Tarhio, J.: Transposition invariant pattern matching for multi-track strings. Nordic Journal of Computing, 2003. 10, 3, s. 185-205.
Online at https://tuhat.halvi.helsinki.fi/portal/services/downloadRegister/14284996/03NJC_LT.pdf

* Lemström, K.: String Matching Techniques for Music Retrieval. Department of Computer Science, Series of Publications A, Report A-2000-4. Online at http://www.cs.helsinki.fi/u/klemstro/THESIS/

The implementations were based on an early draft version of the article, that contained algorithms not included in the published version. Additionally, the implementations may have minor differences from the published version. 

All algorithms are capable of polyphonic searching.

* monopoly: translation invariant, octave equivalent filtering.
* mp: octave equivalent filtering. 
* mp2: translation invariant, octave equivalent filtering. 
* directcheck: translation invariant, octave equivalent searching. 
* directcheck2: translation invariant, octave equivalent searching.
* matchcheck: translation invariant, octave equivalent algorithm for checking the candidates found by filtering methods. 
* shiftorand: exact matches only

For a pattern length of two, directcheck finds also multiple overlapping transposition invariant occurrences, e.g. 65-60 and 65-72, whereas monopoly, mp2 and directcheck2 only find one of the occurrences. ShiftOrAnd only finds the exact matches, and is not capable of reporting which notes matched. 

There are also utilities for handling MIDI files. The utilies require the SMF library by Tadayoshi Funaba. Install it with gem install smf. 

MIDI files can be acquired from the Mutopia Project: http://www.mutopiaproject.org

Usage
-----

require_relative 'lib/utils'

Convert MIDI files:

Create a data directory, put your midi files in the midi directory, and run conversion: 

BPMIR::MidiUtil.convert('midi', 'data')

Load converted data: 

chords = BPMIR::MidiUtil.load('data/polytest.chords')
pp = BPMIR::MidiUtil.load('data/polytest.pp')

Monopoly requires three arguments: chord data, preprocessed data, and a pattern to be searched. 
Chord data is needed for reporting matched notes. The pattern is given as a character string. 

puts BPMIR::monopoly(chords, pp, 'AH')

All the other algorithms require two arguments: chord data and a pattern to be searched. 

puts BPMIR::mp(chords, 'AH')
puts BPMIR::mp2(chords, 'AH')
puts BPMIR::directcheck(chords, 'AH')
puts BPMIR::directcheck2(chords, 'AH')
puts BPMIR::shiftorand(chords, 'AH')

