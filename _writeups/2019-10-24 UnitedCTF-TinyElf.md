---
layout: post
title:  "UnitedCTF - TinyElf Writeup"
date:   2019-10-24 10:30:00 +1300
author: Tiklo
categories: UnitedCTF reversing
---

## TinyElf - Harcore (Medium)

__Preface:__ This was by far one of the hardest and most creative RE challenges to date. I ran into a lot of dead-ends trying to solve it, some of which I will be sharing. I strongly encourage you give this one a try before reading the writeup.

This challenge starts with a given binary (`./tinyelf`) with a size of 128 bytes. Running `file`, we can quickly tell that we are dealing with an ELF binary, with no other details provided.

```
tiklo@thinkpad:~/tinyelf$./tinyelf AAAAAAAAAAA; echo $?
255
```

Running the program at first with a few random inputs yield a return value of 255 (when the desired output is 0). Opening it up in GDB, we run into the first roadblock.

```
./tinyelf": not in executable format: file format not recognized
```

Hmmm... This is interesting. Opening it up in Ghidra, I stumble upon an uncommon sight; Ghidra could not recognize the format the binary had come in. Specifying that it was a x86 Intel 32bit ELF binary did not help either, as all it recognized was some broken assembly code.

Doing a hexdump of the file, it was very clear that the magic ELF bytes had been preserved, but that the header had not. This may explain the problems GDB and Ghidra were having recognizing this binary (details about ELF Headers can be found [here](https://en.wikipedia.org/wiki/Executable_and_Linkable_Format#File_header)).


```
// Sample of an ELF header (Where the first 4 bytes are "Magic")
// Byte 0x4 specifies 32 (0x1) or 64 (0x2) bit - This is a 64 bit binary
// Byte 0x5 specifies Endianness (Little: 0x1, Big: 0x2) - This is using Little Endian
00000000 7f45 4c46 0201 0100 0000 0000 0000 0000
00000010 0200 3e00 0100 0000 c548 4000 0000 0000

// Sample of TinyElf hexdump
// Notice how bytes 0x4 and 0x5 are not following the ELF header format?
00000000 457f 464c 3c58 7402 b30b 3101 40c0 80cd
00000010 0002 0003 5e5e 16eb 2004 0100 0021 0000
```

At this point I was a little worried. I wasn't entirely sure how to proceed as I wasn't entirely confident in my ability to convert hexcode into readable assembly. After a few attempts at manually trying to add a header, I started looking for a less "brute force" approach. Thankfully, it was around this time that Radare2 came to the rescue. After a few warnings during the analysis of the binary, Radare2 was able to identify and decompile the binary. We were in!

Once inside, the distinct lack of main function (or any function for that matter) became apparent. I decided to do some digging, and found a very helpful [article](https://0x00sec.org/t/dissecting-and-exploiting-elf-files/7267) detailing how an ELF binary with a size of 128bytes could be created. In short: It had been directly compiled from x86 Assembly.

At a glance, a small block of assembly seemed to be doing most of the work.

```
│    └────> 0x0100203a      b81f000000     mov eax, 0x1f               
│    ┌────> 0x0100203f      8036db         xor byte [esi], 0xdb
│    ╎╎╎│   0x01002042      8d4c0561       lea ecx, [ebp + eax + 0x61]
│    ╎╎╎│   0x01002046      31d2           xor edx, edx
│   ┌─────> 0x01002048      49             dec ecx
│   ╎╎╎╎│   0x01002049      0211           add dl, byte [ecx]
│   ╎╎╎╎│   0x0100204b      39e9           cmp ecx, ebp
│   └─────< 0x0100204d      75f9           jne 0x1002048
│    ╎╎╎│   0x0100204f      3216           xor dl, byte [esi]
│    ╎╎╎│   0x01002051      08550a         or byte [arg_ah], dl
│    ╎╎╎│   0x01002054      46             inc esi
│    ╎╎╎│   0x01002055      48             dec eax
│    └────< 0x01002056      79e7           jns 0x100203f
│     ╎└──< 0x01002058      ebaf           jmp 0x1002009
```

It seemed like there were two loops at play. The outer loop is a for loop iterating over `eax` (`for i in range(0x1f)` in python). The loop is performing `XOR 0xdb` on each character from the input. This will then be compared to a computed value to check for flag validity. This hints that the flag is of length `0x1f` (or 31 characters).

The second loop is a nested for loop that iterates over `eax + 0x61` (`for i in range(eax + 0x61)` in python). This loop uses program memory, as well as the value of the current character (that has been XOR'ed) to compute a value that is stored in the 8bit register `dl`.

Once the loop is completed, `dl` is XOR'ed with `byte[esi]`, the result is stored in `dl`. `dl` is then OR'ed with the `byte[arg_ah]`, with the result stored in `byte[arg_ah]` (it is worth noting that `arg_ah` is initialized as 0). This shows that our modified input character is being XOR'ed with `dl` with an expected result of 0. `dl` is OR'ed with `byte[arg_ah]` as a check, if it's a non-zero value, the value of `byte[arg_ah]` will also become non-zero, with no posibility to ever set it back to 0 (note the difference between OR and XOR). This means that at the end of the outer loop, the value of `byte[arg_ah]` will show if the flag is valid or not.

This program is using XOR encryption, which we can use to our advantage. If we set a breakpoint at `0x0100204f`, we can check the value of the `dl` register. Once noted, we can step a single instruction, and set the `dl` register to 0, tricking the program into thinking the character was correct and proceeding.

After doing this 31 times (this was somewhat tedious...), I wrote a short python script to XOR each byte with `0x1f` (since XOR encryption is symmetric) and print the flag. And what came out was... _G A R B A G E_. I'm not joking when I say that this was extremely unerving. I was sure I had accounted for everything!

After a lot of digging, I found that I had made a crucial mistake. The line:
> This loop uses program memory, as well as the value of the current character (that has been XOR'ed) to compute a value that is stored in the 8bit register `dl`.

Was the key to my mistake. This issue comes about due to the way a debugger works. A debugger needs to know _where_ a breakpoint has been placed, and in order to do this inserts an opcode `0xCC` at the desired instruction. Since `dl` is being computed based on the memory of the program, it's using `0xCC` as part of it's arithmetic instead of the correct opcode at that address. This is made worse by the fact that the debugger __does not show 0xCC when the program memory is observed in Radare2__. Suffice to say that I learned a lot that day, and after a lot of caffeine fueled fustration, I started my little process again by using the "Step Until Instruction" feature included in Radare2 instead of breakpoints.

After writting all the bytes down again, I ran it through a small python script:

```
dl_bytes = "9d 97 9a 9c a0 ee ea e3 eb eb eb bf e2 ef ef bd ba ea bf b9 ed bd e2 ec bd be e8 eb e2 b8 e2 a6".split()

xor_key = 0xdb
flag = ""
for byte in dl_bytes:
    flag += chr(int(byte, 16) ^ xor_key)
print(flag)
```

And there it was! `FLAG{518000d944fa1db6f97fe309c9}`. What a relief! This calls for another cup of coffee...
