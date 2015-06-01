@echo off
set xv_path=C:\\Xilinx\\Vivado\\2014.4\\bin
call %xv_path%/xelab  -wto b7a17f11189f48289b43bc9fc4e60a52 -m64 --debug typical --relax -L blk_mem_gen_v8_2 -L xil_defaultlib -L secureip --snapshot myRISC_TB_behav xil_defaultlib.myRISC_TB -log elaborate.log
if "%errorlevel%"=="0" goto SUCCESS
if "%errorlevel%"=="1" goto END
:END
exit 1
:SUCCESS
exit 0
