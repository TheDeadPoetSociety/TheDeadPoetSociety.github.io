---
layout: post
title:  "UnitedCTF - FASTre Writeup"
date:   2019-05-17 02:49:32 +1300
author: Tiklo
categories: UnitedCTF reversing
---

## FASTre - Challenges (Hard)

After opening `./FAST` in Ghidra, the dissasembly shows some very interesting results. A static
set of bytes is stored on the stack.
```
  flag_var1 = 0x3b6e7c314a434d46;
  flag_var2 = 0x828140796a3e687c;
  flag_var3 = 0x1a;
```

This already looks like a char array. But this gets confirmed a few lines down, with the call
to `fgets`, showing that `0x14` bytes are being read from standard input and being stored into
`input`.
```
fgets(input,0x14,stdin);
```

With this newly found knowledge, we can retype the above variables to a char array with a maximum
length of 14 (`char[0x14]`). It can also be noted that there is only `0x11` bytes worth of data currently
 on the stack.

A while loop is present, that seems to be iterating over what looks to be the input. A check
check condition is visible to ensure the flag is correct.
```
if ((char)((char)count + input[(long)count]) != flag_var[(long)count])
```
This is a simple arithmetic problem that's easily programmable to get the reverse of the result, which
should in theory print the flag. I wrote a short C script to be able to achieve this while trying to stay as faithful to the
program as I could.

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

                                                                                                                                                            