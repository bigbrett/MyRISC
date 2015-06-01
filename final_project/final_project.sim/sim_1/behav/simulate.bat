@echo off
set xv_path=C:\\Xilinx\\Vivado\\2014.4\\bin
call %xv_path%/xsim myRISC_TB_behav -key {Behavioral:sim_1:Functional:myRISC_TB} -tclbatch myRISC_TB.tcl -view P:/15spring/engs128/workspace/Brett_and_Matt/final_project/final_project/myRISC_TB_behav.wcfg -log simulate.log
if "%errorlevel%"=="0" goto SUCCESS
if "%errorlevel%"=="1" goto END
:END
exit 1
:SUCCESS
exit 0
