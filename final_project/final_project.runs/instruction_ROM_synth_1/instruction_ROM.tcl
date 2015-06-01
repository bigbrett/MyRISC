# 
# Synthesis run script generated by Vivado
# 

set_param gui.test TreeTableDev
debug::add_scope template.lib 1
set_msg_config -id {Common-41} -limit 4294967295
set_msg_config -id {HDL 9-1061} -limit 100000
set_msg_config -id {HDL 9-1654} -limit 100000

create_project -in_memory -part xc7a35tcpg236-1
set_param project.compositeFile.enableAutoGeneration 0
set_param synth.vivado.isSynthRun true
set_msg_config -id {IP_Flow 19-2162} -severity warning -new_severity info
set_property webtalk.parent_dir P:/15spring/engs128/workspace/Brett_and_Matt/final_project/final_project/final_project.cache/wt [current_project]
set_property parent.project_path P:/15spring/engs128/workspace/Brett_and_Matt/final_project/final_project/final_project.xpr [current_project]
set_property default_lib xil_defaultlib [current_project]
set_property target_language VHDL [current_project]
read_ip P:/15spring/engs128/workspace/Brett_and_Matt/final_project/final_project/final_project.srcs/sources_1/ip/instruction_ROM/instruction_ROM.xci
set_property used_in_implementation false [get_files -all p:/15spring/engs128/workspace/Brett_and_Matt/final_project/final_project/final_project.srcs/sources_1/ip/instruction_ROM/instruction_ROM.dcp]
set_property is_locked true [get_files P:/15spring/engs128/workspace/Brett_and_Matt/final_project/final_project/final_project.srcs/sources_1/ip/instruction_ROM/instruction_ROM.xci]

catch { write_hwdef -file instruction_ROM.hwdef }
synth_design -top instruction_ROM -part xc7a35tcpg236-1 -mode out_of_context
rename_ref -prefix_all instruction_ROM_
write_checkpoint -noxdef instruction_ROM.dcp
catch { report_utilization -file instruction_ROM_utilization_synth.rpt -pb instruction_ROM_utilization_synth.pb }
if { [catch {
  file copy -force P:/15spring/engs128/workspace/Brett_and_Matt/final_project/final_project/final_project.runs/instruction_ROM_synth_1/instruction_ROM.dcp P:/15spring/engs128/workspace/Brett_and_Matt/final_project/final_project/final_project.srcs/sources_1/ip/instruction_ROM/instruction_ROM.dcp
} _RESULT ] } { 
  error "ERROR: Unable to successfully create or copy the sub-design checkpoint file."
}
if { [catch {
  write_verilog -force -mode synth_stub P:/15spring/engs128/workspace/Brett_and_Matt/final_project/final_project/final_project.srcs/sources_1/ip/instruction_ROM/instruction_ROM_stub.v
} _RESULT ] } { 
  puts "CRITICAL WARNING: Unable to successfully create a Verilog synthesis stub for the sub-design. This may lead to errors in top level synthesis of the design. Error reported: $_RESULT"
}
if { [catch {
  write_vhdl -force -mode synth_stub P:/15spring/engs128/workspace/Brett_and_Matt/final_project/final_project/final_project.srcs/sources_1/ip/instruction_ROM/instruction_ROM_stub.vhdl
} _RESULT ] } { 
  puts "CRITICAL WARNING: Unable to successfully create a VHDL synthesis stub for the sub-design. This may lead to errors in top level synthesis of the design. Error reported: $_RESULT"
}
if { [catch {
  write_verilog -force -mode funcsim P:/15spring/engs128/workspace/Brett_and_Matt/final_project/final_project/final_project.srcs/sources_1/ip/instruction_ROM/instruction_ROM_funcsim.v
} _RESULT ] } { 
  puts "CRITICAL WARNING: Unable to successfully create the Verilog functional simulation sub-design file. Post-Synthesis Functional Simulation with this file may not be possible or may give incorrect results. Error reported: $_RESULT"
}
if { [catch {
  write_vhdl -force -mode funcsim P:/15spring/engs128/workspace/Brett_and_Matt/final_project/final_project/final_project.srcs/sources_1/ip/instruction_ROM/instruction_ROM_funcsim.vhdl
} _RESULT ] } { 
  puts "CRITICAL WARNING: Unable to successfully create the VHDL functional simulation sub-design file. Post-Synthesis Functional Simulation with this file may not be possible or may give incorrect results. Error reported: $_RESULT"
}
