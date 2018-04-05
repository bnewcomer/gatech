# Benjamin Newcomer & Casey Evanish
# CS 3220 Project 2

import json
import re,sys,os

class Assembler:
	"""Assembler assembles assembly"""

	ISA_JSON_FILE = "isa.json"

	def __init__(self, args):
		# store args (post validation)
		#instruction will have [output,line number,original code, opCode,imm]
		#This will be outputted
		self.instructions = []
		self.IMM_LENGTH = 17
		self.REGISTER_LENGTH = 5
		self.WORD_LENGTH = 32
		self.file = args.file
		self.output = args.output
		self.orig = 0
		self.name = {}
		self.word = {}
		self.lnumber = 0
		self.anumber = 0
		"""verify that all necessary args are present"""
		self.primary = {
		"SYS": ["00111", "",0],
		"EXT": ["00000","",0],
		"LW": ["01010","J",0],
		"SW": ["01110","J",0],
		"BEQ": ["10000","I",1],
		"BLT": ["10001","I",1],
		"BLE": ["10010","I",1],
		"BNE": ["10011","I",1],
		"JAL": ["10111","J",1],
		"ADDI": ["11000","I",0],
		"ANDI": ["11100","I",0],
		"ORI": ["11101","I",0],
		"XORI": ["11110","I",0],
		}
		self.secondary = {
		"SUB": ["01000","R",0],
		"NAND": ["01100","R",0],
		"NOR": ["01101","R",0],
		"NXOR": ["01110","R",0],
		"EQ": ["10000","R",0],
		"LT": ["10001","R",0],
		"LE": ["10010","R",0],
		"NE": ["10011","R",0],
		"ADD": ["11000","R",0],
		"AND": ["11100","R",0],
		"OR": ["11101","R",0],
		"XOR": ["11110","R",0],
		}

		self.system = {
		"RETI": ["10000"],
		"RSR": ["10001"],
		"WSR": ["10010"],
		"SYS": ["00000"],
		}

		self.pseudo = {
		"NOT": ["XORI",self.primary["XORI"]],
		"CALL": ["JAL",self.primary["JAL"]],
		"RET": ["JAL",self.primary["JAL"]],
		"JMP": ["JAL",self.primary["JAL"]],
		"BGT": ["BLT",self.primary["BLT"]],
		"BGE": ["BLE",self.primary["BLE"]],
		"GT": ["LT",self.secondary["LT"]],
		"GE": ["LE",self.secondary["LE"]],
		"SUBI": ["ADDI",self.primary["ADDI"]],
		}

		self.labels = {}

		self.systemRegs = {
		"PCS": 0,
		"IHA": 1,
		"IRA": 2,
		"IDN": 3,
		}

		self.registers = {
		"ZERO": 0,
		"A0": 1,
		"A1": 2,
		"A2": 3,
		"A3": 4,
		"RV": 5,
		"R6": 6,
		"R7": 7,
		"T0": 8,
		"T1": 9,
		"T2": 10,
		"T3": 11,
		"T4": 12,
		"T5": 13,
		"T6": 14,
		"T7": 15,
		"S0": 16,
		"S1": 17,
		"S2": 18,
		"S3": 19,
		"S4": 20,
		"S5": 21,
		"S6": 22,
		"S7": 23,
		"SSP": 24,
		"R25": 25,
		"R26": 26,
		"R27": 27,
		"GP": 28,
		"FP": 29,
		"SP": 30,
		"RA": 31,
		}

	def assemble(self):
		"""assemble() opens the input file, reads it, and
		produces corresponding machine code that is put in
		a mif file."""

		# open file
		fh = open(self.file, 'r')
		# read file
		lines = fh.readlines()
		fh.close()
		outputFile = open(self.output, "w")
		outputFile.write("WIDTH=32;\nDEPTH=2048;\nADDRESS_RADIX=HEX;\nDATA_RADIX=HEX;\nCONTENT BEGIN;\n")
		#print self.twos_comp("5",0)
		for each in lines:
			each = each.strip() + "\n"
			self.translateInstruction(each)
		#print self.instructions
		for each in self.instructions:
			#print each[2]
			if "[" in each[0] and "]" in each[0]:
				outputFile.write(each[0]+"\n")
			elif len(each[0]) == 32:
				outputFile.write("-- @ 0x"+format(each[1]*4,'08x') +":"+each[2])
				outputFile.write(format(each[1],'08x')+" : "+ format(int(each[0], 2),'08x')+";\n")
			elif len(each[0]) < 32:
				#print each
				imm = each[4]
				opCode = each[3]
				if imm in self.labels:
					#print opCode
					outputFile.write("-- @ 0x"+format(each[1]*4,'08x') +":"+each[2])
					immSize = self.WORD_LENGTH - len(each[0])
					#for branches
					if (opCode in self.primary and self.primary[opCode][2]) or (opCode in self.pseudo and self.pseudo[opCode][1][2]):
						#print opCode
						if opCode == "JAL" or opCode == "CALL" or opCode == "JMP":
							#print opCode
							outputFile.write(format(each[1],'08x')+" : "+ format(int(each[0]+self.binary((self.labels[imm]),immSize,immSize),2),'08x')+";\n")
						#for branches
						else:
							outputFile.write(format(each[1],'08x')+" : "+ format(int(each[0]+self.binary((self.labels[imm]-(each[1]+1)),immSize,immSize),2),'08x')+";\n")
					else:
						if each[3] == "SUBI":
							outputFile.write(format(each[1],'08x')+" : "+ format(int(each[0]+ self.negateBin(self.binary((self.labels[imm]*4),immSize,immSize)),2),'08x')+";\n")
						else:
							outputFile.write(format(each[1],'08x')+" : "+ format(int(each[0]+ self.binary((self.labels[imm]*4),immSize,immSize),2), '08x')+";\n")
				elif imm in self.name:
					outputFile.write("-- @ 0x"+format(each[1]*4,'08x') +":"+each[2])
					immSize = self.WORD_LENGTH - len(each[0])
					immediate = self.checkImmLength(self.name[imm], immSize, each[2])
					if each[3] == "SUBI":
						outputFile.write(format(each[1],'08x')+" : "+ format(int(each[0]+ self.negateBin(immediate),2),'08x')+";\n")
					else:
						outputFile.write(format(each[1],'08x')+" : "+ format(int(each[0]+ immediate,2), '08x')+";\n")
				elif imm in self.word:
					outputFile.write("-- @ 0x"+format(each[1]*4,'08x') +":"+each[2])
					immSize = self.WORD_LENGTH - len(each[0])
					#print self.word[imm]
					#print each[2]
					immediate = self.checkImmLength(bin(self.word[imm])[2:], immSize, each[2])
					if each[3] == "SUBI":
						outputFile.write(format(each[1],'08x')+" : "+ format(int(each[0]+ self.negateBin(immediate),2),'08x')+";\n")
					else:
						outputFile.write(format(each[1],'08x')+" : "+ format(int(each[0]+ immediate,2), '08x')+";\n")
				else:
					outputFile.write("-- @ 0x"+format(each[1]*4,'08x') +":"+each[2])
					immSize = self.WORD_LENGTH - len(each[0])
					immediate = self.checkImmLength(self.checkHex(imm), immSize, each[2])
					if each[3] == "SUBI":
						outputFile.write(format(each[1],'08x')+" : "+ format(int(each[0]+ self.negateBin(immediate),2),'08x')+";\n")
					else:
						outputFile.write(format(each[1],'08x')+" : "+ format(int(each[0]+ immediate,2), '08x')+";\n")
		outputFile.write("["+format(self.lnumber,'08x')+"..07ff] : 0000;\nEND;")
		outputFile.close()

	def checkImmLength(self,imm, immSize, instr):
		length = len(imm)
		if length <= immSize:
			imm2 = imm.zfill(immSize)
			length = len(imm)
			return ((immSize -length)*imm[0]) + imm
		else:
			leftMost = imm[:length-immSize]
			rightMost = imm[length-immSize:]
			if (leftMost.count("1") == length-immSize or leftMost.count("0") == length-immSize) and leftMost[-1] == rightMost[0]:
				return rightMost
			else:
				if os.path.isfile(self.output):
					os.remove(self.output)
					sys.exit('The immediate value in '+instr.strip()+' is too long and cannot be truncated')
				else:
					sys.exit('The immediate value in '+instr.strip()+' is too long and cannot be truncated')
		#sys.exit('Error!')

	def translateInstruction(self,instr):
		org1 = ".ORIG"
		org2 = ".ORG"
		name = ".NAME"
		word = ".WORD"
		label = ":"
		#This takes care or .ORIG statements
		if (org1 in instr or org2 in instr) and name not in instr and word not in instr and label not in instr:
			#print instr
			line = instr.split()
			instrList = [p.strip() for p in line]
			currLoc = self.toDec(instrList[1])
			newLoc = (currLoc/4) - 1
			if self.orig != currLoc:
				self.instructions.append(["["+format(self.lnumber, '08x')+".."+format(newLoc, '08x')+"] : 0000;",self.lnumber,""])
				self.lnumber = newLoc +1
			#else:
			#	self.lnumber += 1 
			self.anumber = currLoc
			self.orig = currLoc
			#print currLoc

		#This takes care of .WORD s
		elif (word in instr) and name not in instr and org1 not in instr and org2 not in instr:
			#a: .WORD (label or dec or hex)
			if (label in instr):
				label = instr.strip().split(":")
				labelName = label[0]
				wordVal = re.sub(".WORD","",label[1]).strip()
				newWord = re.sub("[^xX0-9\-]+","",wordVal)
				if newWord != '0x' and newWord != '0X' and newWord != wordVal:
					#print wordVal
					self.word[labelName] = self.anumber
					#instruction will have [output,line number,original code, opCode,imm]
					self.instructions.append(["",self.lnumber,instr,"",wordVal])
				else:
					#print self.toDec(wordVal)
					self.word[labelName] = self.anumber
					dec = self.toDec(wordVal)
					self.instructions.append(["",self.lnumber,instr,"", str(dec)])
				self.lnumber += 1
				self.anumber += 4
			# .WORD label or dec or hex
			else:
				imm = re.sub(".WORD","",instr.strip())
				#instruction will have [output,line number,original code, opCode,imm]
				self.instructions.append(["",self.lnumber,instr,"",imm])
				self.lnumber += 1
				self.anumber += 4
		#This takes care of labels 
		elif (label in instr) and name not in instr and word not in instr and org1 not in instr and org2 not in instr:
			label = instr.split(":")
			label = label[0].strip()
			self.labels[label] = self.lnumber
			#print self.labels
		#This takes care of .NAME statements 
		elif (name in instr) and org1 not in instr and word not in instr and org2 not in instr and label not in instr:
			line = re.sub("\.NAME|\s","",instr)
			line = line.split("=")
			self.name[line[0]] = self.checkHex(line[1])
			#print self.name
		elif org1 not in instr and name not in instr and word not in instr  and org2 not in instr and label not in instr:
			#gets rid of comments
			instr = instr.lstrip()
			#print instr
			if ';' in instr:
				index = instr.find(";")
				instr = instr[:index]+"\n"
			#line = re.sub("(\t\s\r)","",instr,1)
			line = re.sub("\s","<>",instr,1)
			#print line
			#line = line.strip()
			line = line.split("<>")
			#print line
			opCode = line[0].upper()
			#print opCode+":"+instr
			if opCode in self.system:
				#print "instr: "+instr
				#print "code: " + line[1]
				self.makeInstructionSystem(line[1], opCode, self.system[opCode][0], instr)
				self.lnumber += 1
				self.anumber += 4
			elif opCode in self.primary:
				self.makeInstruction(line[1], self.primary[opCode][1], opCode, self.primary[opCode][0], instr, self.primary[opCode][2])
				self.lnumber += 1
				self.anumber += 4
				#self.makeNoop()
			elif opCode in self.secondary:
				self.makeInstruction(line[1], self.secondary[opCode][1], opCode, self.secondary[opCode][0], instr, self.secondary[opCode][2])
				self.lnumber += 1
				self.anumber += 4
				#self.makeNoop()
			elif opCode in self.pseudo:
				self.makeInstructionPseudo(line[1], self.pseudo[opCode][1][1], opCode, self.pseudo[opCode][1][0], instr)
				self.lnumber += 1
				self.anumber += 4
				#self.makeNoop()
			#rest = line[1]
			#print opCode

		# decipher ryOrImmRy

		# decipher rzOrImm
	
	def makeNoop(self):
		#instruction will have [output,line number,original code, opCode,imm]
		self.instructions.append(["0"*32,self.lnumber,"Noop\n","",""])
		self.lnumber += 1
		self.anumber += 4
		self.instructions.append(["0"*32,self.lnumber,"Noop\n","",""])
		self.lnumber += 1
		self.anumber += 4
		self.instructions.append(["0"*32,self.lnumber,"Noop\n","",""])
		self.lnumber += 1
		self.anumber += 4
		self.instructions.append(["0"*32,self.lnumber,"Noop\n","",""])
		self.lnumber += 1
		self.anumber += 4

	def makeInstructionSystem(self, code, opCode, opCodeInstr, instr):
		#instruction will have [output,line number,original code, opCode,imm]
		#print "opCode: "+opCode
		if opCode == "RETI" or opCode == "SYS":
			self.instructions.append([self.primary["SYS"][0]+"0000000000000000000000"+opCodeInstr,self.lnumber,instr,opCode])
		elif opCode == "RSR":
			code = code.strip().split(",")
			RxNum = code[0].strip().upper()
			Rx = self.binary(self.registers[RxNum],self.REGISTER_LENGTH,self.REGISTER_LENGTH)
			SyNum = code[1].strip().upper()
			Sy = self.binary(self.systemRegs[SyNum],self.REGISTER_LENGTH,self.REGISTER_LENGTH)
			self.instructions.append([self.primary["SYS"][0]+Rx+Sy+"000000000000"+opCodeInstr,self.lnumber,instr,opCode])
		elif opCode == "WSR":
			code = code.strip().split(",")
			SxNum = code[0].strip().upper()
			#print SxNum
			Sx = self.binary(self.systemRegs[SxNum],self.REGISTER_LENGTH,self.REGISTER_LENGTH)
			RyNum = code[1].strip().upper()
			Ry = self.binary(self.registers[RyNum],self.REGISTER_LENGTH,self.REGISTER_LENGTH)
			self.instructions.append([self.primary["SYS"][0]+Sx+Ry+"000000000000"+opCodeInstr,self.lnumber,instr,opCode])

	def makeInstructionPseudo(self,code,instrType,opCode, opCodeInstr, instr):
		#NOT Rx,Ry => XORI Rx,Ry,-1
		if opCode == "NOT":
			code = code.strip().split(",")
			RxNum = code[0].strip().upper()
			Rx = self.binary(self.registers[RxNum],self.REGISTER_LENGTH,self.REGISTER_LENGTH)
			RyNum = code[1].strip().upper()
			Ry = self.binary(self.registers[RyNum],self.REGISTER_LENGTH,self.REGISTER_LENGTH)
			imm = "1"*self.IMM_LENGTH
			self.instructions.append([opCodeInstr+Ry+Rx+imm,self.lnumber,instr.strip() + "=>" + self.pseudo[opCode][0]+" "+RxNum+", "+RyNum+", "+"-1\n",opCode,imm])
		#CALL Imm(Ri) => JAL RA,Imm(Ri) and JMP Imm(Ri) => JAL R6,Imm(Ri)
		elif opCode == "CALL" or opCode == "JMP":
			code = re.sub("\)",'',code.strip())
			code = re.split("\(",code)
			imm = code[0].strip()
			Ry = self.binary(self.registers[code[1].strip().upper()],self.REGISTER_LENGTH,self.REGISTER_LENGTH)
			if opCode == "CALL":
				Rx = self.binary(self.registers["RA"],self.REGISTER_LENGTH,self.REGISTER_LENGTH)
				self.instructions.append([opCodeInstr+Ry+Rx,self.lnumber,instr.strip()+"=>"+self.pseudo[opCode][0]+" RA, "+imm+"("+Ry+")\n",opCode,imm])
			elif opCode == "JMP":
				Rx = self.binary(self.registers["R6"],self.REGISTER_LENGTH,self.REGISTER_LENGTH)
				self.instructions.append([opCodeInstr+Ry+Rx,self.lnumber,instr.strip()+"=>"+self.pseudo[opCode][0]+" R6, "+imm+"("+Ry+")\n",opCode,imm])
		#RET => JAL R6,0(RA)
		elif opCode == "RET":
			Rx = self.binary(self.registers["R6"],self.REGISTER_LENGTH,self.REGISTER_LENGTH)
			imm = "0"*self.IMM_LENGTH
			Ry = self.binary(self.registers["RA"],self.REGISTER_LENGTH,self.REGISTER_LENGTH)
			self.instructions.append([opCodeInstr+Ry+Rx+imm,self.lnumber,instr.strip()+"=>"+self.pseudo[opCode][0]+" R6, "+imm+"(RA)\n",opCode,imm])
		#BGT Ry,Rx,Label => BLT Rx,Ry,Label and BGE Ry,Rx,Label => BLE Rx,Ry,Label
		elif opCode == "BGT" or opCode == "BGE":
			code = code.strip().split(",")
			RxNum = code[1].strip().upper()
			Rx = self.binary(self.registers[RxNum],self.REGISTER_LENGTH,self.REGISTER_LENGTH)
			RyNum = code[0].strip().upper()
			Ry = self.binary(self.registers[RyNum],self.REGISTER_LENGTH,self.REGISTER_LENGTH)
			imm = code[2].strip()
			self.instructions.append([opCodeInstr+Rx+Ry,self.lnumber,instr.strip()+"=>"+self.pseudo[opCode][0]+" "+RxNum+", "+RyNum+", "+imm.strip()+"\n",opCode,code[2].strip()])
		#GT Rx,Rz,Ry => LT Rx,Ry,Rz and GE Rx,Rz,Ry => LE Rx,Ry,Rz
		elif opCode == "GT" or opCode == "GE":
			code = code.strip().split(",")
			RxNum = code[0].strip().upper()
			Rx = self.binary(self.registers[RxNum],self.REGISTER_LENGTH,self.REGISTER_LENGTH)
			RyNum = code[2].strip().upper()
			Ry = self.binary(self.registers[RyNum],self.REGISTER_LENGTH,self.REGISTER_LENGTH)
			RzNum = code[1].strip().upper()
			Rz = self.binary(self.registers[RzNum],self.REGISTER_LENGTH,self.REGISTER_LENGTH)
			self.instructions.append([self.primary["EXT"][0]+Ry+Rz+Rx+"0000000"+opCodeInstr, self.lnumber,instr.strip()+"=>"+self.pseudo[opCode][0]+" "+RxNum+", "+RyNum+", "+RzNum+"\n",opCode])
		#SUBI Rx,Ry,Imm => ADDI Rx,Ry,-Imm
		elif opCode == "SUBI":
			code = code.split(",")
			RxNum = code[0].strip().upper()
			Rx = self.binary(self.registers[RxNum],self.REGISTER_LENGTH,self.REGISTER_LENGTH)
			RyNum = code[1].strip().upper()
			Ry = self.binary(self.registers[RyNum],self.REGISTER_LENGTH,self.REGISTER_LENGTH)
			imm = code[2].strip()
			self.instructions.append([opCodeInstr+Ry+Rx,self.lnumber,instr.strip()+"=>"+self.pseudo[opCode][0]+" "+RxNum+", "+RyNum+", -"+imm.strip()+"\n",opCode,code[2].strip()])

	def makeInstruction(self, code, instrType, opCode, opCodeInstr, instr, isBranch):
		#for J-type: Rx, imm(Ry) instructions 
		if instrType == "J":
			code = re.sub("\)",'',code)
			code = re.split("\(|,",code)
			Rx = self.binary(self.registers[code[0].strip().upper()],self.REGISTER_LENGTH,self.REGISTER_LENGTH)
			Ry = self.binary(self.registers[code[2].strip().upper()],self.REGISTER_LENGTH,self.REGISTER_LENGTH)
			self.instructions.append([opCodeInstr+Ry+Rx,self.lnumber,instr,opCode,code[1].strip()])
		#for I-Type: Rx, Ry, imm
		elif instrType == "I":
			code = code.split(",")
			Rx = self.binary(self.registers[code[0].strip().upper()],self.REGISTER_LENGTH,self.REGISTER_LENGTH)
			Ry = self.binary(self.registers[code[1].strip().upper()],self.REGISTER_LENGTH,self.REGISTER_LENGTH)
			if isBranch:
				#print "branch" bookmark1
				self.instructions.append([opCodeInstr+Rx+Ry,self.lnumber,instr,opCode,code[2].strip()])
			else:
				self.instructions.append([opCodeInstr+Ry+Rx,self.lnumber,instr,opCode,code[2].strip()])
		#for R-type: Rx, Ry, Rz
		elif instrType == "R":
			code = code.split(",")
			Rx = self.binary(self.registers[code[0].strip().upper()],self.REGISTER_LENGTH,self.REGISTER_LENGTH)
			Ry = self.binary(self.registers[code[1].strip().upper()],self.REGISTER_LENGTH,self.REGISTER_LENGTH)
			Rz = self.binary(self.registers[code[2].strip().upper()],self.REGISTER_LENGTH,self.REGISTER_LENGTH)
			self.instructions.append([self.primary["EXT"][0]+Ry+Rz+Rx+"0000000"+opCodeInstr, self.lnumber,instr,opCode])

	#returns binary twos complement of Hex or integer
	def checkHex(self,someString):
		#print someString
		#if this is a hex
		if 'x' in someString or 'X' in someString:
			hexString = re.split("x|X",someString)[1].strip()
			return bin(int(hexString,16))[2:].zfill(len(hexString)*4)
		#if this is a integer
		else:
			num = int(someString)
			if num > 0:
				binNum = "0"+bin(num)[2:]
				return self.binary(num,len(binNum),len(binNum))
			else:
				binNum = "1"+bin(num)[3:]
				return self.binary(num,len(binNum),len(binNum))


	#takes in either a hex string or decimal and turns it into a signed decimal
	def toDec(self, val):
		if ('x' in val or 'X' in val):
			hexStringList = re.split("x|X",val) 
			hexString = hexStringList[1].strip()
			return int(hexString,16)
		else:
			decString = val.strip()
			return int(decString)

	#finds the binary representation of an int x in 2s complement. Force it to make it length long
	def binary(self,x,length, numBit):
		if x < 0:
			new= bin((eval("0b"+str(int(bin(x)[3:].zfill(length).replace("0","2").replace("1","0").replace("2","1"))))+eval("0b1")))[2:].zfill(length)
		else:
			binNum = bin(x)[2:].zfill(numBit)
			new = ((length - len(binNum))*binNum[0])+binNum
		if new > length:
			return new[len(new)-length:]
		else:
			return new

	def negateBin(self,bin):
		newString = ''
		for each in bin:
			if each == '1':
				newString += "0"
			elif each == "0":
				newString += "1"
		return self.binary(int(newString,2)+1,self.IMM_LENGTH,self.IMM_LENGTH)


