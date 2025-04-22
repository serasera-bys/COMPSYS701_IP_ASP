FPGA SImulation Procedure

1. Open Quartus Prime.
2. Open 'File' tab and select 'Open Project'. 
3. Choose 'GP1.qpf' and click open
4. Compile all files
5. Connect USB cable to USB Blaster Port
6. Open 'Tools' tab and open 'programmer'
7. Select 'hardware setup' and check if 'USB Blaster' already connected
8. Click add file and select 'output_file' and select 'GP1.sof'
9. Click 'Auto Detect' and select '5CSEMA5' and click 'OK'
10. Click 'Start' and wait until the process done
11. When process done, all 7 Segment Display will light up. You can switch the switches and the LED in front of the switch will light on
12. if you want to change the prog_mem.mif, write an assembly program 
13. Use assembler called '32bitAssembler.py' to convert .asm file to .mif file. Save .asm file and assembler in same file 
14. Open Command Prompt
15. Type cd ....(assembler and asm file located)
16. Type 'phyton 32bitAssembler.py (your asm file name).asm
17. The file will be created and the file name is output.mif
18. Change the old prog_mem.mif file to the new output.mif
19. Rename output.mif to prog_mem.mif
20. Open quartus prime again and select 'Processing' tab and select 'Update Memory Initialization File'
21. Run 'Assembler' on Quartus Prime
22. Open 'Tools' tab and open 'programmer'. Click start and wait until progress done
23. After that the board will change according .mif file

