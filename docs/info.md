<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

This project working by taking in a 6 bit input where 3 bits are real and 3 bits are complex. Then the 3 bit sample is loaded into a SIPO which outputs a 3 bit sample to the 4 point DIF FFT core when the SIPO is ready. Then the FFT Core outputs an array that contains the computed FFT to be inputed into the PISO. That then turns the array into a serial output ready for the output of the top file. The FFT is computed only using subtraction and addition from a simplificaton done in the sources:

## How to test

To test this FFT you can run `make` in the `test` directory. However, as of now this FFT does not work as it is one frame of due to incorrect handshaking delays.

## Resources

- Claude: Due to time constraints I used a LLM to make the cocotb testbench, might be why it does not work!
- ZIPCPU: https://zipcpu.com/dsp/2018/10/02/fft.html
- Bevan Bass: https://www.ece.ucdavis.edu/~bbaas/dissertation/pdf.ps/thesis.1side.pdf
- https://www.brainkart.com/article/Decimation-In-Frequency-(DIFFFT)_13033/
- https://studylib.net/doc/10311597/decimation-in-frequency--dif--radix-2-fft-douglas-l.-jones
- https://web.mit.edu/6.111/www/f2017/handouts/FFTtutorial121102.pdf
- https://www.geeksforgeeks.org/digital-logic/sipo-shift-register/
