# Processor
## NAME (NETID)

Hunter Habersaat (hah50)

## Description of Design

The processor consists of 5 stages: Fetch, Decode, Execute, Memory, and Writeback. Each stage of the processor is connected through registers (F/D, D/X, X/M, and M/W) which latch on the falling edge. Stalling and branch flushing logic is present in this veresion of the processor.

In the Fetch stage, the Program Counter (PC) is updated based on branch decisions, which are managed by a multiplexed control signal (branch_mux_out). When a branch is taken, NOP instructions are injected into the pipeline to prevent unintended execution of instructions that would otherwise follow the branch. The Decode stage interprets the opcode, assigning values to control signals based on the instruction type and sending operand values to the ALU for execution. The Execute stage performs calculations using the ALU or processes multiplication/division operations with stall logic implemented to wait for mult/div operations to complete. The Memory and Writeback stages handle data memory operations and update the register file respectively.

## Bypassing

The bypassing logic is primarily applied in the Execute stage, where operand values might depend on the results of instructions that are still in the pipeline.

M/W to Execute Bypassing: If an instruction in the Memory stage writes to a register that is read by an instruction in the Execute stage, we forward the value from the Memory/Writeback (M/W) pipeline register directly to the Execute stage. This is done through the bypass_from_mw_A and bypass_from_mw_B signals, which detect if the ex_rs or ex_rt register fields in the Execute stage match the destination register of the instruction in the Memory stage (xm_rd). This forwarding applies for R-type, ADDI, LW, SETX, and JAL instructions in the M/W stage.

W/X to Execute Bypassing: Similarly, if an instruction in the Writeback stage is writing to a register that an instruction in the Execute stage is reading, we bypass the result from the Writeback register directly. This forwarding is handled by bypass_from_wx_A and bypass_from_wx_B signals. The bypass occurs when the ex_rs or ex_rt fields in the Execute stage match the destination register in Writeback (mw_ctrl_writeReg) and the Writeback instruction type requires it. This enables seamless forwarding from completed operations without additional stalls.

Special Cases: Certain instructions, i.e., BLT, BNE, and JR, may need the result of a preceding instruction for their comparison operations. For these cases, bypass_from_mw_blt_A, bypass_from_mw_blt_B, bypass_from_wx_blt_A, and bypass_from_wx_blt_B signals are used to forward data to the Execute stage if a hazard exists with the target register of a prior instruction in either the Memory or Writeback stages. Additionally, exceptions triggered in the pipeline (e.g., arithmetic overflow) are bypassed using bypass_from_mw_exception_A and bypass_from_mw_exception_B.

## Stalling

Stalling is managed for multiplication/divison through a stall_pipeline signal, which is generated based whether there is an in-progress mult/div operation. In cases where a mult/div operation is detected, the pipeline halts, starting from the cycle where we latch the operands to the cycle where we raise result_RDY. Additionally, when a branch is taken, we flush the Fetch and Decode registers and injecting NOP instructions since they will no longer be correct. This pipeline stall is applied to all registers.

Aside from this, we stall when the "data_hazard" wire is raised, which happens in the few cases where there is a data hazard that cannot be fixed via bypassing. For both the EX and FD registers (as well as the nop into the DX register), we turn off the in_enable when the (data_hazard or pipeine_stall) AND not branch_taken because taking a branch overrides a stall in these cases.


## Optimizations

None beyond the original spec unless you include branch prediction and stall logic.

Branch prediction through the branch flushing logic, which injects NOPs into the pipeline only when a branch is taken, minimizing the performance impact of incorrect branch paths. Stall logic selectively stalls the pipeline only in cases where bypassing cannot resolve hazards, such as with load dependencies or mult/div operations in progress.

## Bugs

None currently