---
layout: post
title:  "UnitedCTF - FASTre Writeup"
date:   2019-10-17 02:49:32 +1300
author: Tiklo
categories: UnitedCTF reversing
---

## FASTre - Challenges (Hard)

After opening `./FAST` in Ghidra, the disassembly shows some interesting results. A static
set of bytes is stored on the stack (potentially has something to do with the flag?).
```
  flag_var1 = 0x3b6e7c314a434d46;
  flag_var2 = 0x828140796a3e687c;
  flag_var3 = 0x1a;
```

This really looks like a char array, but I am not jumping to conclusions just yet
and keep reading (SPOILER: This theory gets confirmed a few lines down).
```
fgets(input,0x14,stdin);
```
The program uses a system call to `fgets`, meaning that `0x14` bytes are being read from
STDIN and being stored into the variable `input` (meaning we can retype `input` to be a
known `char[0x14]`). With this newly found knowledge, we can safely assume this will be directly
compared to the values stored on the stack, and therefore retype the above variables to a char 
array with a maximum length of 20 (`char[0x14]`). It should be noted that there is only `0x11` bytes
worth of data currently stored on the stack (the flag is of length 17 or using mod(17)?).

```
if ((char)((char)count + input[(long)count]) != flag_var_str[(long)count])
```
A while loop is present, that is iterating over each character in `char[0x14] input`. A check condition
is present to ensure each character taken from STDIN matches the stored bytes after a little arithmetic. 
We can solve for `input` instead of `flag_var_str` to get the reverse of the result, which will give a sequence
of bytes each within valid ASCII range (hinting about the presence of a flag). I wrote a short C script to be able to achieve this while trying 
to stay as faithful to the program as I could.

```
# @author Tiklo
# @date 23/09/2019

#include <stdio.h>																																			
int main() {
    flag_var1 = 0x3b6e7c314a434d46;
    flag_var2 = 0x828140796a3e687c;
    flag_var3 = 0x1a;

    int count = 0;
    while(count < 0x14) {
        int val = (char)*(char *)((long)&address + count) - (char)count;
        // Ensures non-negative values
        if (val < 0) {
            val = 256 + val;
        }

        printf("%c", val);
        count ++;
    }
}
```
In terminal: `tiklo@thinkpad:~$./solve` yields `FLAG-wh4t_4_m3ss`. And there is the flag!

                                                                                                                                                            