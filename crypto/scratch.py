from crypt import Crypt

def specialshift(text, shift1, shift2):
	"""letters A-L shift 3, letters
	M-Z shift 5.
	"""

	# shift A-L
	end = text.index('l') + 1
	atol = Crypt.shift(text, shift1)
	atol = atol[:end]

	# shift M-Z
	start = text.index('m')
	mtoz = Crypt.shift(text, shift2)
	mtoz = mtoz[start:]

	domain = atol + mtoz
	return domain

cipher = "DTZBTSYEHOLHAHYKHALHB".lower()
domain = "abcdefghijklmnopqrstuvwxyz"
otherDomain = specialshift(domain, 3, 5)
print domain
print otherDomain

def getDomain(text):
	return domain

c = Crypt()
cipher = c.mcrypt(plain, mapFactory=specialshift, mapFactoryArgs=(3,5))
decipher = c.mcrypt(cipher, domain=otherDomain, mapFactory=getDomain)


print cipher
print decipher
