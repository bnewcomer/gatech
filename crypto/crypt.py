##############################################################################
# Encryption: A History Implemented
# 
# author: Benjamin Newcomer
# 
# released: July 3rd, 2015
# 
# Python version: 2.7.6
# 
# description: the crypt module defines several functions which 
# implement several substitution and transposition ciphers, ranging from the 
# simple Caesar cipher to the more complex Enigma cipher. This module focuses 
# on pre-computing ciphers and ignores modern day ciphers like DES, AES, RSA,
# which already have implementations in most language libraries.
##############################################################################

import re
import random

#################################### STATIC DATA ##################################

DEFAULT_DOMAIN = "abcdefghijklmnopqrstuvwxyz"
DEFAULT_FENCES = 3
DEFAULT_SHIFT = 3
DEFAULT_REPS = 26
LEFT = 0
RIGHT = 1
DEFAULT_ROTORS = (1,)
DEFAULT_PLUG = ()
DEFAULT_REFLECTOR = ()

    ################################ FUNCTIONS ###############################

def mcrypt(plaintext, domain=DEFAULT_DOMAIN, mapFactory=None, mapFactoryArgs=None):
    """ mcrypt implements a monoalphabetic substitution
    encryption scheme. Monoalphabetic ciphers are those for which
    there is a one-to-one mapping between the plaintext domain and
    the ciphertext domain that does not change during encryption.
    The Caesar cipher (see crypt.caesar below) is a simple example 
    of this. 

    mcrypt() works by permuting the input domain according
    to some function, dmap, that maps each element of the domain onto
    some other element of the same domain, which is called permutation
    mapping. 

    Monoalphabetic substitution encryption was used in early
    history for centuries until frequency analysis was developed by 
    the ninth century Arabic scientist Abu Yusuf Ya'qub ibn Is-haq 
    ibn as-Sabbah ibn omran ibn Ismail al-Kindi. Eventually it was 
    replaced by polyalphabetic substitution.

    inputs:
        plaintext (string): plaintext to encrypt
        domain (string): the domain of the plaintext. see crypt.DEFAULT_DOMAIN 
            for an example.
        mapFactory (function): a function that defines a permutation mapping 
            between the given domain and itself. The function must accept
            the domain (string) as the first argument and may optionally
            accept *dmapArgs as additional arguments.
        mapFactoryArgs (list): a list of additional arguments to pass
            to the dmap function.
    output:
        (string): the plaintext encrypted using the given inputs.

    usage:
        import crypt

        plain = "meetmeatturodelarovira"
        shiftN = 5
        out = crypt.mcrypt(
            plaintext=plain,
            mapFactory=crypt.shift,
            mapFactoryArgs=(shiftN,crypt.LEFT)
            )
        print out

        >>  'rjjyrjfyyzwtijqfwtanwf'
    """

    # default dmap and domain
    if mapFactory is None:
        mapFactory = shift
    if domain is None:
        domain = DEFAULT_DOMAIN

    # create cipher mapping using the dmap function
    if mapFactoryArgs is not None:
        mapping = mapFactory(domain, *mapFactoryArgs)
    else:
        mapping = mapFactory(domain)

    # strip any characters not in domain
    encodedDomain = domain.encode('string_escape')
    domainRegex = r"[^" + encodedDomain + r"]"
    plaintext = re.sub(domainRegex, "", plaintext)

    # map plaintext using cipher alphabet mapping.
    # map from one domain with only one mapping,
    # so we give a dmap with all 0's so that the
    # first mapping (only mapping) is always used
    ciphertext = polyDomainMap(
        chars=plaintext, 
        domainA=domain, 
        domains=(mapping,)
        )

    return ciphertext


def pcrypt(plaintext, reps=DEFAULT_REPS, domain=DEFAULT_DOMAIN, mapFactory=None,
    mapFactoryArgs=None, domainMap=None, domainMapArgs=None):
    """ pcrypt implements a simple polyalphabetic substitution encryption scheme.
    Polyalphabetic encryption is similar to monoalphabetic encryption in that
    plaintext is mapped from one domain to another, but the domain can
    change during encryption. This means that one character in the plaintext
    can be mapped using a different mapping function than another character.
    This provides much needed security by rendering frequency analysis much more
    difficult in most cases and impossible in the most complex case (see crypt.vernam).

    pcrypt works by permuting the domain multiple times using the domainMap function 
    to produce a list of permuted domains that are then used to map each character in the
    plaintext. For each character, the mapping to use is chosen using a list of
    mapping indices passed as the first argument in the domainMapArgs list. If 
    no list is given, the first mapping is used for all characters (which results
    in a monoalphabetic mapping). 

    Polyalphabetic ciphers were used from their discovery in the mid 1400s
    by Leon Battista Alberti to the present. Although more advanced forms
    of encryption have become the standard, polyalphabetic encryption has
    played a key role in history, most notably in the form of the Enigma
    machine used by the German military in WWII.

    inputs:
        plaintext (string): plaintext to encrypt.
        reps (int > 0): the number of additional domains to produce. For example, 
            1 would produce one reordered domain and would be the same as a
            monoalphabetic substitution.
        domain (string): the domain of the plaintext. see crypt.DEFAULT_DOMAIN 
            for an example.
        mapFactory (function): a function that defines a permutation mapping 
            between the given domain and itself. The function must accept
            the domain (string) as the first argument and reps as the
            second, which defines the number of domains that should be returned.
            mapFactory may optionally accept *mapFactoryArgs as additional arguments.
            The function must return a list of permuted domains.
        mapFactoryArgs (list): a list of additional arguments to pass
            to the mapFactory function.
        domainMap (function): a function that maps the plaintext to ciphertext using the
            given list of mappings. the function must accept the plaintext as the first
            argument and the list of domains as the second argument. *domainMapArgs will
            be passed in if additional arguments are needed.
        domainMapArgs (list): optional list of additional arguments to be passed to
            domainMap. The default domainMap function accepts a list of domain indices
            as the first element in this list. The list of indices is used to choose
            which mapping to use for each character in the plaintext.
    output:
        (string): the plaintext encrypted using the given inputs.

    usage:
        import crypt

        domain = "abcdefghijklmnopqrstuvwxyz"
        plain = "hello"
        key = [0, 1, 2, 3, 0]
        out = crypt.pcrypt(
            plaintext=plain, 
            reps=len(domain),
            domain=domain,
            mapFactory=crypt.polyShift,
            domainMap=crypt.polyDomainMap,
            domainMapArgs=(key,)
            )
        print out

        >>  'hfnoo'
    """

    # default dmap, domainMap, and domain
    if mapFactory is None:
        mapFactory = shift
    if domainMap is None:
        domainMap = polyDomainMap

    # create cipher domains using the mapFactory function
    # seed takes the values [0, reps]. This creates
    # a vigenere square if default arguments are used.
    if mapFactoryArgs is not None:
        mappings = mapFactory(domain, reps, *mapFactoryArgs)
    else:
        mappings = mapFactory(domain, reps)
 
    # strip any characters not in domain
    encodedDomain = domain.encode('string_escape')
    domainRegex = r"[^" + encodedDomain + r"]"
    plaintext = re.sub(domainRegex, "", plaintext)

    # map each character in the plaintext using the
    # constructed list of domains and the given
    # mapping function
    if domainMapArgs is not None:
        ciphertext = domainMap(plaintext, domain, mappings, *domainMapArgs)
    else:
        ciphertext = domainMap(plaintext, domain, mappings)

    return ciphertext


def railfence(plaintext, numFences=DEFAULT_FENCES):
    """railfence implements the Rail Fence encryption algorithm, which
    is a form of transposition cipher. This cipher was widely used by the
    Greeks in the form of the Scytale, a wooden rod around which a piece
    of cloth could be wrapped and written on. The message was only revealed
    when the cloth was wrapped around a rod of the same diameter. 
    Unfortunately this method is easily broken and is not used today. However,
    the Rail Fence cipher is an important stepping stone in cryptography history.

    inputs:
        plaintext (string): plaintext to be encrypted.
        numfences (int > 0): the number of fences to use.
    output:
        (string): encrypted text.

    usage:
        import crypt

        plain = "meetmeatturodelarovira"
        numfences = 5
        out = crypt.railfence(plain, numfences)
        print out

        >>  'merareaoraetdottevmuli'
    """

    # create fences. each fence will hold a 
    # set of non-adjacent characters that are
    # chosen depending on the number of fences.
    fences = [list() for i in range(numFences)]

    for i, c in enumerate(plaintext):
        # append each char to the 
        # correct fence
        fences[i % numFences].append(c)

    # flatten list of fences into
    # a single list and join that
    # to make a single string.
    # ciphertext = fence1 + fence2 + ...
    ciphertext = list()
    map(ciphertext.extend, fences)
    ciphertext = "".join(ciphertext)

    return ciphertext


def caesar(plaintext, shiftN=DEFAULT_SHIFT, domain=DEFAULT_DOMAIN):
    """caesar implements a Caesar cipher, which is one of the
    simplest monoalphabetic substitution ciphers. Caesar ciphers map
    from one domain to the same domain shifted by an integer i. The
    most common domain is the english alphabet and the historic shift
    for the Caesar cipher is 3. This cipher was useful when it first
    appeared in 50 B.C., but because the key has only a few
    possibilities (len(domain) - 1, 25 for the english alphabet), the 
    cipher is very easy to crack using brute force.

    caesar uses the crypt.mcrypt function with crypt.shift as the
    dmap and a the input key given as an additional argument to crypt.shift.
    The default key is 3, which would give the classic Caesar cipher.
    The ciphertext can be unencrypted by passing the ciphertext into
    crypt.caesar with the same shift, but negated.

    inputs:
        plaintext (string): plaintext to encrypt
        key (int): the number of letters to shift the plaintext
                alphabet to create the cipher alphabet.
        domain (string): the domain of the plaintext (a string containing
            all characters that can appear in the plaintext, with ordering)
    output:
        (string): the plaintext encrypted using a Caesar
                cipher with a shift defined by the input key.

    usage:
        import crypt

        plain = "meetmeatturodelarovira"
        shift = 5
        out = crypt.caesar(plain, shift)
        print out

        >>  'rjjyrjfyyzwtijqfwtanwf'        
    """

    ciphertext = mcrypt(
        plaintext=plaintext,
        mapFactory=shift,
        mapFactoryArgs=(shiftN,LEFT)
        )

    return ciphertext


def wordPermute(plaintext, key, domain=DEFAULT_DOMAIN):
    """wordPermute implements a simple permutation mapping using
    a keyword. To obtain the mapping between the original domain
    and the remapped domain, the algorithm prepends the key to the
    domain (ex 'key' + 'abcdefghijklmnopqrstuvwxyz'), and then deletes
    all repeated letters, so that each letter in the domain only appears
    once. This newly mapped domain is then used to encrypt the plaintext.

    Permutation mapping with a keyword is a simple cipher and can be easily
    broken. Its major flaw is that unless a sufficiently complex key is
    used, the end portion of the domain will map to itself (typically, 'xyz'
    would map to 'xyz').

    inputs:
        plaintext (string): the plaintext to be encrypted.
        key (string): the key that is used to encrypt the plaintext.
        domain (string): a string that contains one occurence of every
            possible character that can appear in the plaintext.
    output:
        (string): the encrypted ciphertext.

    usage:
        import crypt

        plain = "meetmeatturodelarovira"
        key = "onix"
        out = crypt.wordPermute(plain, key)
        print out

        >>  'jaasjaosstqlxahoqlueqo'
    """

    ciphertext = mcrypt(
        plaintext=plaintext,
        domain=domain,
        mapFactory=permuteWithKey,
        mapFactoryArgs=(key,)
        )

    return ciphertext


def vigenere(plaintext, key, domain=DEFAULT_DOMAIN):
    """vigenere implements a Vigenere cipher which is the most famous
    polyalphabetic substitution cipher. The Vigenere cipher uses a 
    Vigenere square and a keyword to map plaintext to ciphertext. The
    Vigenere square is a list of every mapping achievable by
    shifting the domain. For the english alphabet, this means that the
    first row of the square is the normal alphabet, the second row is
    the alphabet shifted by one character, and so on. To encrypt plaintext,
    the key is repeated so that each character in the plaintext is associated
    with one character in the key. Then, for each character in the plaintext,
    the corresponding key character's position in the alphabet is used to
    look up a certain row in the Vigenere square. That row defines the
    permutation mapping to be used for that character. For example, if the key
    was "hello", then four different monoalphabetic substitutions would be used,
    one for each unique letter in the key.

    vigenere uses the crypt.pcrypt function with crypt.polyShift as the dmap and 25 reps.
    crypt.polyDomainMap is then used to map the plaintext to the list of domains using
    the given key.

    The Vigenere cipher was a breakthrough in crypto technology and a much needed
    respite for cryptographers in the 1500s. This cipher remained unbreakable for over
    300 years until Friedrich Kasiski published a break in 1863.

    inputs:
        plaintext (string): the plaintext to encrypt.
        key (string): the key to use when encrypting the plaintext.
    outputs:
        (string): the encrypted ciphertext.

    usage:
        import crypt

        plain = "meetmeatturodelarovira"
        key = "onix"
        out = crypt.vigenere(plain, key)
        print out

        >>  'armqariqhhzlrrtxfbdffn'
    """

    # convert key into list of integers where each int
    # represents the row in the vigenere square that
    # should be used for encryption. if the plaintext is
    # longer than the key, repeat the key.
    keylen = len(key)
    keynums = [
        domain.find(key[i % keylen]) 
        for i in range(len(plaintext))
        ]

    # implement cipher using
    # pcrypt with the correct
    # number of domains and
    # the keynums obtained from
    # the key
    ciphertext = pcrypt(
        plaintext=plaintext, 
        reps=len(domain),
        domain=domain,
        mapFactory=polyShift,
        domainMap=polyDomainMap,
        domainMapArgs=(keynums,)
        )

    return ciphertext


def vernam(plaintext, pad, domain=DEFAULT_DOMAIN):
    """vernam implements a Vernam cipher which is a type of
    one time pad encryption. The algorithm produces a pad that
    is the same length as the plaintext. 

    The one time pad is theoretically impossible to break because
    if each letter is encrypted using a different key, then there
    is no relation between the encrypted letters and there are no
    footholds for breaking the cipher. However, the one time pad
    is impossible to implement in a perfect fashion because doing so
    requires truly random sequences of keys and it requires that the 
    sender and receiver are perfectly synchronized in their use of
    keys.

    inputs:
        plaintext (string): the text to encrypt.
        pad (string): a list of characters that will be used to encrypt
            the plaintext.
        domain (string): a string that contains one occurence of every
            possible character that can appear in the plaintext.
    output:
        (string): the encrypted text.

    usage:
        import crypt
                   
        plain = "meetmeatturodelarovira"

        # generate pad using the reverse 
        # alphabet
        pad = "abcdefghijklmnopqrstuvwxyz"
        pad = pad[::-1]
        pad = pad[:len(plain)]

        out = crypt.vernam(plain, pad)
        print out

        >>  'vctfzqtbceeaoiakygsoue'
    """

    # clip or repeat pad so that
    # len(pad) == len(plaintext)
    padlen = len(pad)
    plainlen = len(plaintext)
    if padlen > plainlen:
        pad = pad[:plainlen]
    elif padlen < plainlen:
        pad = "".join([
            pad[i % padlen] 
            for i in range(plainlen)
            ])

    # convert each character in pad and plaintext 
    # to an integer that represents the character's
    # position in the domain
    padNums = [domain.find(c) for c in list(pad)]
    textNums = [domain.find(c) for c in list(plaintext)]

    # perform xor of each number in the 
    # plaintext with each number in the pad
    # and mod len(domain) to obtain cipher numbers.
    # index domain with cipher numbers
    domainlen = len(domain)
    xormodfind = lambda x, y: domain[(x^y) % domainlen]
    cipherlist = map(xormodfind, padNums, textNums)
    ciphertext = "".join(cipherlist)

    return ciphertext


def enigma(plaintext, plugboardConfig=DEFAULT_PLUG, rotorConfig=DEFAULT_ROTORS, 
    reflectorConfig=DEFAULT_REFLECTOR, domain=DEFAULT_DOMAIN):
    """The enigma machine was an electromechanical cipher machine used during World
    War II by the German military. The first Enigma machine was broken by Poland a few
    years prior to the war, but by the time the war began, the machine had been improved
    and was unbreakable. Poland, knowing that they would not survive the war
    independently, shared their intelligence with the Allied powers shortly before the
    war began. Britain pursued the Enigma machine throughout the war and in a few years
    developed a machine that could automatically discover the key used in Enigma messages
    using cribs, or known plaintext/ciphertext pairings. The breakage of the Enigma machine
    was one of the most important achievements of cryptanalysis!

    The enigma machine used a combination of rotors, a plugboard, and a reflector to
    effectively produce close to one-time pad encryption strength. For more information
    see https://en.wikipedia.org/wiki/Enigma_machine.

    enigma attempts to replicate the behavior of the enigma machine using software.
    The virtual rotors here each provide permutation mapping based on a randomly generated
    keyword, the plugboard can switch any number of letters, and the reflector can be
    randomly assigned. This algorithm implemenets the general behavior, but the exact behavior
    of the machines depends on how they are used and which generations and models are examined.
    For example, the Enigma machines used between three and five rotors, but this algorithm
    can use any number of rotors.

    inputs:
        plaintext (string): the text to encrypt
        plugboardConfig (list of tuples of chars): the plugboard input is used to
            configure the plugboard. Each char represents a character in the domain. 
            Each tuple will replace the first character with the second and
            vice versa. The list of tuples must not have any duplicate characters.
            The config can switch any number of characters.
        rotorConfig (list of ints < 100): which rotors to use. The numbers are used to 
            seed a permutation mapping so that each int refers to one unique mapping 
            (one rotor).
        reflectorConfig (list of tuples of characters): the reflector input is used to
            configure the reflector. Each tuple will replace the first letter with
            the second and vice versa. Each letter in the domain must appear once
            and only once in the given configuration.
        domain (string): the domain used for the encryption.
    outputs:
        (string): the encrypted ciphertext

    usage:
        import crypt

        plain = "hello"
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

        print cipher
        print deciphered

        >>  'vztnl'
        >>  'hello'
    """

    # generate plugboard, rotor, and reflector
    plugboard = generateSwappedMapping(domain, plugboardConfig)
    rotors = [generateRandomMapping(domain, i) for i in rotorConfig]
    reflector = generateSwappedMapping(domain, reflectorConfig)

    # encrypt text one character at a time
    ciphertext = ""
    for i, c in enumerate(plaintext):

        # run through plugboard
        c = monoDomainMap(c, domain, plugboard)

        # pass through all rotors
        for rotor in rotors:
            c = monoDomainMap(c, domain, rotor)

        # run through reflector
        c = monoDomainMap(c, domain, reflector)

        # pass back through rotors
        # in reverse
        for rotor in reversed(rotors):
            c = monoDomainMap(c, rotor, domain)

        # run back through plugboard
        c = monoDomainMap(c, domain, plugboard)

        # shift rotors. the first rotor shifts
        # each time, the second rotates after
        # the first rotor has performed a full
        # rotation, and so on.
        for j, rotor in enumerate(rotors):
            if j == 0 or i % len(domain)*j == 0:
                rotors[j] = shift(rotor, 1)

        ciphertext = ciphertext + c

    return ciphertext


def generateRandomMapping(domain, seed):
    """generateRandomMapping generates a random permutation mapping, which replicates the
    behavior of the rotors used in the Enigma machine. This method generates the same
    mapping for the same seed. This feature is necessary so that the same rotor
    configuration can be achieved for decryption.

    inputs:
        seed (int): an integer in the range [0, 99] that identifies a mapping. Any mapping
            generated with the same seed will have the same configuration.
        domain (string): a string that contains one occurence of every character allowed.
            This is the domain that the mapping is based on.
    output:
        (string): a permutation mapping dependant on the seed.

    usage:
        import crypt

        domain = "abcdefghijklmnopqrstuvwxyz"
        seed = 40
        rotor = crypt.generateRandomMapping(domain, seed)
        print rotor

        >>  'warbmoctdylenfpqgshuvixjzk'
    """

    # generate domain list
    mapping = list(domain)

    # shuffle list according
    # to seed
    seedLambda = lambda: seed/100.
    random.shuffle(mapping, seedLambda)

    mapping = "".join(mapping)
    return mapping


def generateSwappedMapping(domain, config):
    """generateSwappedMapping generates a mapping from the input domain where the
    characters found at the positions specified by the input config are swapped.
    
    inputs:
        domain (string): a string that contains one occurence of every character allowed.
            This is the domain that the mapping is based on.
        config (list of tuples of chars): the config input is used to
            configure the mapping. Each char represents a character in the domain. 
            Each tuple will replace the first character with the second and
            vice versa. The list of tuples must not have any duplicate characters.
            The config can switch any number of characters.
    output:
        (string): the swapped mapping.

    usage:
        import crypt

        domain = "abcdefghijklmnopqrstuvwxyz"
        config = [
                ('f', 'd'), 
                ('b', 'n'), 
                ('j', 'z')
                ]
        swapped = crypt.generateSwappedMapping(
            domain, config)
        print swapped

        >>  'ancfedghizklmbopqrstuvwxyj'
    """

    mapping = list(domain)

    for pair in config:
        # swap characters
        index0 = mapping.index(pair[0])
        index1 = mapping.index(pair[1])
        mapping[index0] = pair[1]
        mapping[index1] = pair[0]

    mapping = "".join(mapping)
    return mapping


def shift(text, shift, direction=LEFT):
    """shift wraps a string around itself according to
    the input shift. For example, wrapping a string by one would 
    place the last letter of the string in the first position
    and shift the rest of the letters right by one position.

    inputs:
        text (string): the text to be shifted.
        shift (int): the number of places to shift the string.
        direction (1 or 0): which direction to shift.
    output:
        (string): the shifted text.

    usage:
        import crypt

        str = "abc"
        shift = 1
        out = crypt.shift(str, shift)
        print c

        >>  'bca'
    """

    # defaults
    if direction is None:
        direction = LEFT

    # format shift to range 
    # [0, len(text) - 1]
    shift = shift % len(text)

    # shift the text, depnding on
    # the direction
    if direction == RIGHT:
        last = text[-shift:]
        first = text[:-shift]
    elif direction == LEFT:
        last = text[shift:]
        first = text[:shift]
    shifted = last + first

    return shifted


def polyShift(text, shifts, direction=LEFT):
    """polyshift produces a list of shifted texts,
    where each entry has been shifted by the number
    indicated by each element in shifts.

    inputs:
        text (string): text to shift.
        shifts (int): the number of shifts to perform.
        direction (1 or 0): which direction to perform
            the shift.
    output:
        (string list): list of shifted texts

    usage:
        import crypt

        text = "abc"
        shifts = 3
        out = crypt.polyshift(text, shifts)
        print out

        >>  ('abc', 'bca', 'cab')
    """

    # defaults
    if direction is None:
        direction = LEFT

    output = list()

    for shiftN in range(shifts):
        output.append(shift(text, shiftN, direction))

    return output


def permuteWithKey(text, key):
    """_wordPermute() rearranges the given text by placing the
    characters of the given key at the beginning (without repititions)
    and placing the rest of the characters of the text after.
    The key must be a subset of the characters in the text.

    inputs:
        text (string): the text to be permuted.
        key (string): the key to appear at the begininng of the text.
    output:
        (string): the permuted text.

    usage:
        import crypt

        text = "abcdef"
        key = "abbe"
        out = crypt.permuteWithKey(
            text, key)
        print out

        >>  'abecdf'
    """
    # combine text and key
    text = key + text

    # remove duplicate characters
    output = ""
    for c in text:
        if output.find(c) == -1:
            output = output + c

    return output


def generatePad(length, domain):
    """_generatePad() generates a one time pad of characters
    fromt he given domain with the given length.

    inputs:
        length (int): length of the pad.
        domain (string): possible characters to be in the pad.
    output:
        (list): list of characters.
    """
    # TODO: complete generate pad method
    raise NotImplementedError()
    
 
def monoDomainMap(char, domainA, domainB):
    """_domainMap() translates one data point from domainA to domainB.
    There must be a 1 to 1 mapping between domains. In this 
    function, the mapping is performed by matching the
    location of the data point in domain A (using indices)
    with the data point at the same location in domain B.

    inputs:
        char (string): data point in domainA to be mapped.
        domainA (string): a definition for domainA (example: 
            the english alphabet).
        domainB (string): a definition for domainB that is the
            same length as domainA.
    output:
        (string): data mapped into domain B.

    usage:
        import crypt

        char = "b"
        domainA = "abc"
        domainB = "123"
        out = crypt.domainMap(
            char, domainA, domainB)
        print out

        >>  '2'
    """

    if len(char) == 1:
        index = domainA.find(char)
        mappedC = domainB[index]
        return mappedC


def polyDomainMap(chars, domainA, domains, dmap=None):
    """polyDomainMap translates data from domainA to a list of domains.
    There must be a 1 to 1 mapping between A and each other domain. 
    In this function, the mapping is performed by matching the 
    location of each data point in domain A (using indices) with 
    the data point at the same location in one of the other domains. The
    domain is chosen from the list of domains using a third list of integers
    where each integer specifies which domain to use for the character in
    the same position.

    inputs:
        chars (string): data in domain A to be mapped.
        domainA (string): a definition for domain A (example: 
            the english alphabet).
        domains (list): a list of domains that each have the same
            length as domain A.
        dmap (int list): a list that is the same length as the
            data. For each corrsponding position in the data,
            the integer given will be used to select a domain to
            map to.
    output:
        (string): data mapped into another domain according to a map.

    usage:
        import crypt

        chars = "hello"
        domainA = "helowrd"
        domains = (
            "1234567",
            "abcdefg"
            )

        # map even positioned character to domain[0] and 
        # map odd positioned letters to domain[1]
        dmap = [i % 2 for i, c in enumerate(chars)]
        
        out = crypt.polyDomainMap(
            chars, domainA, domains, dmap)
        print out

        >>  '1b3c4'
    """

    # defaults
    if dmap is None:
        dmap = [0 for x in range(len(chars))]

    output = ""

    for i, c in enumerate(chars):

        # get the index of the character
        # from its domain (ex a -> 0)
        index = domainA.find(c)

        # choose the domain using the index
        # of the current character in chars
        # and the entry in dmap in the 
        # corresponding location
        whichDomain = dmap[i]
        outDomain = domains[whichDomain]

        # map character to new domain,
        # append to output
        charOut = monoDomainMap(c, domainA, outDomain)
        output = output + charOut

    return output
