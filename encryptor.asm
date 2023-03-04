.data
	key: .asciiz "\nEnter the key(Integers only - max 10 digits): "
	filePathRead: .asciiz "\nEnter the full file path(use double backward slashes ('\\') instead of singles ('\')) of the file to encrypt/decrypt: "
	filePathDestination: .asciiz "\nEnter the full file path(use double backward slashes ('\\') instead of singles ('\')) of the destination file: "
	#Example C:\\Users\\myPC\\Desktop\\myFile.txt
	text: .asciiz "\nEnter the text to encrypt: "
	filePathReadStorage: .space 200
	filePathDestinationStorage: .space 200
	# max number of bytes the user can input for encryption. The user must input n-1 number of characters
	# as the null terminator must be at the end of the input
	# if you exceed, it will take in n-1 characters and discard the rest.
	textStorage: .space 500
	null_term: .asciiz "\0"
	modePrompt: .asciiz "\n1. Encrypt \n2. Decrypt \n3. Exit \n Make a selection: "
	errorSelectMode: .asciiz "\nInvalid Selection. Try again!\n"
	encryptModePrompt: .asciiz "\n1. Encrypt an existing file \n2. Create a new file and encrypt \n3. Go back \nMake a selection: "
	fileSuccessPrompt: .asciiz "\nProcess completed sucessfully!\n"
	fileErrorPrompt: .asciiz "\nProcess was not successful! Check file discription return code"

.text

j main

#file oath of the file to read
getFilePathRead:
	# Output the key request prompt
	li $v0, 4
	# address of first character in the array of characters of the prompt to print out
	la $a0, filePathRead
	syscall

	# get the file path and store it in 'filePathReadStorage'
	li $v0, 8
	la $a0, filePathReadStorage
	li $a1, 500
	syscall

	la $t0, filePathReadStorage
	LoopPathRead:
		lb $t2, 0($t0)
		beqz $t2, eLoopPathRead
		addi $t0, $t0, 1
		j LoopPathRead
	eLoopPathRead:
		subi $t0, $t0, 1
		la $t1, null_term
		lb $t2, 0($t1)
		sb $t2, 0($t0)

	jr $ra

#the file path for the file to encrypt to
getFilePathDestination:
	# Output the key request prompt
	li $v0, 4
	# address of first character in the array of characters of the prompt to print out
	la $a0, filePathDestination
	syscall

	# get the file path and store it in 'filePathStorage'
	li $v0, 8
	la $a0, filePathDestinationStorage
	li $a1, 500
	syscall

	la $t0, filePathDestinationStorage
	LoopPathDestination:
		lb $t2, 0($t0)
		beqz $t2, eLoopPathDestination
		addi $t0, $t0, 1
		j LoopPathDestination
	eLoopPathDestination:
		subi $t0, $t0, 1
		la $t1, null_term
		lb $t2, 0($t1)
		sb $t2, 0($t0)

	jr $ra


getKey:
	# Output the key request prompt
	li $v0, 4
	# address of first character in the array of characters of the prompt to print out
	la $a0, key
	syscall

	# Get user input as integer
	li $v0, 5
	syscall

	# copy the address where the key was stored into register $s0
	move $s0, $v0

	jr $ra

getUserInput:
	# print prompt to request
	li $v0, 4
	la $a0, text
	syscall

	# Get the text to encrypt
	li $v0, 8
	la $a0, textStorage
	li $a1, 500
	syscall

	jr $ra

readFile:
	# use syscall code 13 to open/create the file
	li $v0, 13
	# $a0 register gets the address of the first character in the array of characters that holds the destination file
	la $a0, filePathReadStorage
	# load flag (1 for write, 0 for read, 9 for append) into register $a1
	li $a1, 0
	# load mode (0 for ignore) into $a2
	li $a2, 0
	syscall

	# copy the return value (file_description (negative number for an error, positive for no error)) int register $t1
	move $t0, $v0

	# read data from the opened file
	li $v0, 14
	move $a0, $t0
	la $a1, textStorage
	li $a2, 500
	syscall

	# close the file
	li $v0, 16
	# copy the file description that was stored in register $t0 (see line 78) into register $a0
	move $a0, $t0
	syscall

	jr $ra

EncryptMode:
	encryptInput:
		jal getFilePathDestination
		jal getUserInput
		jal getKey

		# load the address of the first character in the array of characters that we want to encrypt into register $a0
		la $a0, textStorage

		j Loop_Chars_Encrypt

	encryptFile:
		jal getFilePathRead
		jal getKey
		jal getFilePathDestination
		jal readFile

		# load the address of the first character in the array of characters that we want to encrypt into register $a0
		la $a0, textStorage

	# loop throught the characters one after the other and increase its value by the encryption key
	Loop_Chars_Encrypt:
		# load the first byte in the address in register $t1 offset 0 to register $t2
		lbu $t0, 0($a0)
		# if the value we loaded into $t2 is 0(null-terminator or end of the array of characters),
		# exit the encrypt function
		beqz $t0, exitEncrypt
		# add the encryption key which was stored in register $s0 into register $t2
		# which holds a single character in the array of characters the user inputed
		# thereby encrypting the character
		xor $t0, $t0, $s0
		addi $s0, $s0, 1
		xor $t0, $t0, $s0
		addi $s0, $s0, 1
		xor $t0, $t0, $s0
		addi $s0, $s0, 1
		xor $t0, $t0, $s0
		addi $s0, $s0, 1
		xor $t0, $t0, $s0
		# save the encryoted character where the enencrypted character was
		sb $t0, 0($a0)
		# increase the address in $t1 by 1 thereby moving 1 byte next  leading to the next char in the array
		addi $a0, $a0, 1
		# jump back to Loop_Chars (line 57) and repeat the process.
		j Loop_Chars_Encrypt

	exitEncrypt:
		jal writeToFile
		j selectMode

DecryptMode:
	jal getFilePathRead
	jal readFile
	jal getFilePathDestination
	jal getKey
	# load the address of the first character in the array of characters that we want to encrypt into register $a0
	la $a0, textStorage

	Loop_Chars_Decrypt:
		li $t1, 10
		# load the first byte in the address in register $t1 offset 0 to register $t2
		lbu $t0, 0($a0)
		# if the value we loaded into $t2 is 0(null-terminator or end of the array of characters),
		# exit the encrypt function
		beqz $t0, exitDecrypt
		# add the encryption key which was stored in register $s0 into register $t2
		# which holds a single character in the array of characters the user inputed
		# thereby encrypting the character
		xor $t0, $t0, $s0
		addi $s0, $s0, 1
		xor $t0, $t0, $s0
		addi $s0, $s0, 1
		xor $t0, $t0, $s0
		addi $s0, $s0, 1
		xor $t0, $t0, $s0
		addi $s0, $s0, 1
		xor $t0, $t0, $s0
		# save the encryoted character where the enencrypted character was
		sb $t0, 0($a0)
		# increase the address in $t1 by 1 thereby moving 1 byte next  leading to the next char in the array
		addi $a0, $a0, 1
		subi $t1, $t1, 1
		# jump back to Loop_Chars (line 57) and repeat the process.
		j Loop_Chars_Decrypt

	exitDecrypt:
		jal writeToFile
		j selectMode

writeToFile:
	# $t0 register keepts the base address of the array of characters
	la $t0, textStorage
	# use syscall code 13 to open/create the file
	li $v0, 13
	# $a0 register gets the address of the first character in the array of characters that holds the destination file
	la $a0, filePathDestinationStorage
	# load flag (1 for write, 0 for read, 9 for append) into register $a1
	li $a1, 1
	# load mode (0 for ignore) into $a2
	li $a2, 0
	syscall

	# copy the return value (file_description (negative number for an error, positive for no error)) int register $t1
	move $t0, $v0

	# use syscall code 15 to write to file
	li $v0, 15
	# copy the file description that was stored in register $t0 (see line 78) into register $a0
	move $a0, $t0
	# load the address of the first character in the array of characters that we want to encrypt into register $a1
	la $a1, textStorage
	# specify the number of bytes we want to write to the file. (Note, it needs to be at least the same or more
	# than the number of bytes used for the user's input text)
	li $a2, 500
	syscall

	# use syscall code 16 to close the file and update it
	li $v0, 16
	# copy the file description that was stored in register $t0 (see line 78) into register $a0
	move $a0, $t0
	syscall

	bge $t0, 0, fileSuccess
	blt $t0, 0, fileError

	fileSuccess:
		li $v0, 4
		la $a0, fileSuccessPrompt
		syscall
		j end
	fileError:
		li $v0, 4
		la $a0, fileErrorPrompt
		syscall
	end:
	jr $ra

selectMode:
	li $v0, 4
	la $a0, modePrompt
	syscall

	li $v0, 5
	syscall

	beq $v0, 1, encryptType
	beq $v0, 2, decrypt
	beq $v0, 3, exit

	li $v0, 4
	la $a0, errorSelectMode
	syscall

	j selectMode

	encryptType:
		li $v0, 4
		la $a0, encryptModePrompt
		syscall

		li $v0, 5
		syscall

		beq $v0, 1, encryptFile
		beq $v0, 2, encryptInput
		beq $v0, 3, selectMode

		li $v0, 4
		la $a0, errorSelectMode
		syscall

		j encryptType
	decrypt:
		jal DecryptMode
		j selectMode

main:
jal selectMode

exit:
	li $v0, 10
	syscall

