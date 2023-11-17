# Zig-wc

a command line utility like wc written in zig.

## Step One

In this step your goal is to write a simple version of wc, let’s call it zigwc
that takes the command line option -c and outputs the number of bytes in a file.

If you’ve done it right your output should match this:

```
>zigwc -c test.txt
  342190 test.txt
```

## Step Two

In this step your goal is to support the command line option -l that outputs the
number of lines in a file.

If you’ve done it right your output should match this:

```
>zigwc -l test.txt
    7145 test.txt
```

## Step Three

In this step your goal is to support the command line option -w that outputs the
number of words in a file. If you’ve done it right your output should match
this:

```
>zigwc -w test.txt
   58164 test.txt
```

## Step Four

In this step your goal is to support the command line option -m that outputs the
number of characters in a file. If the current locale does not support multibyte
characters this will match the -c option.

You can learn more about programming for locales here

For this one your answer will depend on your locale, so if can, use wc itself
and compare the output to your solution:

```
>wc -m test.txt
  339292 test.txt

>zigwc -m test.txt
 339292 test.txt
```

If it doesn’t, check your code, fix any bugs and try again. If it does,
congratulations!
