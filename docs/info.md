<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works
This project computes a 4-point DIF FFT with 1 6 bit complex input, then outputs 1 6 bit complex output. This is achieved by having an "SIPO" that instead of loading a bit at a time loads 2 6 bit inputs (6 bits for real and 6 bits for imaginary -> 1 complex sample) then outputs 4 6 bit real samples alongside 4 6 bit imagimary samples. This is then fed into a 4-point DIF FFT, which outputs the computed frames. The output of the FFT is then fed into a "PISO" which takes the 4 6 bit real results and 4 6 bit imaginary results as an input then outputs 1 6 bit real result and 1 6 bit imaginary result(1 compelx result).

The 4-point DIF FFT is implemented by the follwoing equations:
A_r = in_real_0 + in_real_2
B_r = in_real_1 + in_real_3
C_r = in_real_0 - in_real_2
D_r = in_img_1 - in_img_3
A_i = in_img_0 + in_img_2
B_i = in_img_1 + in_img_3
C_i = in_img_0 - in_img_2
D_i = -(in_real_1 - in_real_3)
out_real_0 = A_r + B_r
out_real_1 = A_r - B_r
out_real_2 = C_r + D_r
out_real_3 = C_r - D_r
out_img_0  = A_i + B_i
out_img_1  = A_i - B_i
out_img_2  = C_i + D_i
out_img_3  = C_i - D_i

The derevation for these equations is sourced from ZipCPUs documentation on their FFT Core, Bevan Bass's dissertation, and brainkart.

SIPO: This works by starting a counter once there is a valid input, during the working state(counter is less than 3) it loads the incoming samples into seperate parallel registers. Once the counter had counted 4 samples it resets and starts loading a new frame.

PISO: This just implements the inverse of the "SIPO"

## How to test

To test this FFT you can run `make` in the `test` directory. 

## Resources

- Deepseek: Helped write testbench, had some minor issues but ended up fixing them on the first try! Also combinded all the seperate module files into one big top, this was orginally done to combat "test" error I was getting that it could not the modules. The real fix was just updating the info.yaml file.
- ZIPCPU: https://zipcpu.com/dsp/2018/10/02/fft.html
- Bevan Bass: https://www.ece.ucdavis.edu/~bbaas/dissertation/pdf.ps/thesis.1side.pdf
- https://www.brainkart.com/article/Decimation-In-Frequency-(DIFFFT)_13033/
- https://studylib.net/doc/10311597/decimation-in-frequency--dif--radix-2-fft-douglas-l.-jones
- https://web.mit.edu/6.111/www/f2017/handouts/FFTtutorial121102.pdf
- https://www.geeksforgeeks.org/digital-logic/sipo-shift-register/
