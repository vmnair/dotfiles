# C Programming Notes

## Rules in software development
1. 99% success is failure
2. Spending time in learning programming tools can time in development and 
debugging.
3. Computer programs cannot tolerate _small_ mistakes.
4. Passing test cases does not guarantee a program is correct.
5. Producing correct output does not mean that a program is correct.
6. Assume program will fail and develop a strategy to detect and correct mistakes.
7. No tools can replace a _clear mind_.

### Utility Functions
1. `diff` function
- `diff` function determines if two files are different.
- `w` argument ignores whitespace
- `q` argument makes the program suppress display of the lines that are different.

```c 
    diff -q file1.c file2.c
```

