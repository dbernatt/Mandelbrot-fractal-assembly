# Mandelbrot fractal in Assembly

![](images/mandelbrot.gif)

## Mandelbrot set

The Mandelbrot set has become popular outside mathematics both for its aesthetic appeal and as an example of a complex structure arising from the application of simple rules. It is one of the best-known examples of mathematical visualization, mathematical beauty, and motif.

## Usage

```
1.	$ nasm -f win32 mandelbrot.asm
```

```
2.	$ nlink mandelbrot.obj -lio -lmio -lgfx -o mandelbrot.exe
```

```
3.	$ ./mandelbrot.exe
```
