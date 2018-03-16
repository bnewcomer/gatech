##############################################################################
# Encryption Tests
# 
# author: Benjamin Newcomer
# 
# released: July 3rd, 2015
# 
# Python version: 2.7.6
# 
# description: this file performs tests for each of the top level functions
# defined in the crypt module.
##############################################################################

import crypt

# plain texts are chosen either from homework 4
# or randomly. Expected values are computed by hand
# (feel free to check my work). Ciphers are considered
# working when their output matches the expected output

#TODO: work out how to decipher each cipher
#TODO: update documentations

def testRailfence():

	plain = "meetmeatturodelarovira"
	expected = "merareaoraetdottevmuli"
	numfences = 5

	out = crypt.railfence(plain, numfences)

	print "test railfence (scytale):"
	print "numfences: " + str(numfences)
	print "plain: " + plain
	print "cipher: " + out

	assert(out == expected)

	print "..............."


def testCaesar():

	plain = "meetmeatturodelarovira"
	expected = "rjjyrjfyyzwtijqfwtanwf"
	shift = 5

	out = crypt.caesar(plain, shift)

	print "test caesar:"
	print "shift: " + str(shift)
	print "plain: " + plain
	print "cipher: " + out

	assert(out == expected)

	print "..............."


def testSpecialCaesar():


	def specialshift(text, shift1, shift2):
		"""letters A-L shift 3, letters
		M-Z shift 5.
		"""

		# shift A-L
		end = text.index('l') + 1
		atol = crypt.shift(text, shift1)
		atol = atol[:end]

		# shift M-Z
		start = text.index('m')
		mtoz = crypt.shift(text, shift2)
		mtoz = mtoz[start:]

		domain = atol + mtoz
		return domain

	plain = "meetmeatturodelarovira"

	cipher = crypt.mcrypt(
		plain, 
		mapFactory=specialshift, 
		mapFactoryArgs=(3,5)
		)

	print "test special caesar:"
	print "shifts: 3, 5"
	print "plain: " + plain
	print "cipher: " + cipher
	print "..............."


def testWordPermute():

	plain = "meetmeatturodelarovira"
	expected = "jaasjaosstqlxahoqlueqo"
	key = "onix"

	out = crypt.wordPermute(plain, key)

	print "test word permute:"
	print "key: " + key
	print "plain: " + plain
	print "cipher: " + out

	assert(out == expected)

	print "..............."


def testVigenere():

	plain = "meetmeatturodelarovira"
	expected = "armqariqhhzlrrtxfbdffn"
	key = "onix"

	out = crypt.vigenere(plain, key)

	print "test vigenere:"
	print "key: " + key
	print "plain: " + plain
	print "cipher: " + out

	assert(out == expected)

	print "..............."


def testVernam():

	plain = "meetmeatturodelarovira"
	expected = "vctfzqtbceeaoiakygsoue"

	# generate pad from homework 4
	pad = "abcdefghijklmnopqrstuvwxyz"
	pad = pad[::-1]
	pad = pad[:len(plain)]

	out = crypt.vernam(plain, pad)

	print "test vernam:"
	print "pad: " + pad
	print "plain: " + plain
	print "cipher: " + out
	
	assert(out == expected)

	print "..............."

def testEnigma():

    plain = "hello"
    # cipher = "dmfiu"
    rconfig = (40, 50, 10)
    plugboard = [
    	('f', 'd'), 
    	('b', 'n'), 
    	('j', 'z')
    	]

    domain = "abcdefghijklmnopqrstuvwxyz"
    a = domain[:len(domain)/2]
    b = domain[len(domain)/2:]
    reflector = [(a[i], b[-i]) for i in range(len(a))]

    cipher = crypt.enigma(
        plaintext=plain,
        rotorConfig=rconfig,
        plugboardConfig=plugboard,
        reflectorConfig=reflector
        )

    deciphered = crypt.enigma(
    	plaintext=cipher,
        rotorConfig=rconfig,
        plugboardConfig=plugboard,
        reflectorConfig=reflector
    	)

    print "test: enigma"
    print "plain: " + plain
    print "rotorConfig: " + repr(rconfig)
    print "plugboard: " + repr(plugboard)
    print "reflector: " + repr(reflector)
    print "cipher: " + cipher
    print "deciphered: " + deciphered

    assert(plain == deciphered)

    print "..............."

# run all tests
testRailfence()
testCaesar()
testWordPermute()
testVernam()
testVigenere()
testEnigma()
print "all tests have passed"