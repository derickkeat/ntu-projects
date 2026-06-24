from typing import Dict, List, Set, Optional
from bril import Function, Instruction, Label, EffectOperation

class BasicBlock:
    def __init__(self, label: str):
        self.label = label
        self.instructions: List[Instruction] = []
        self.predecessors: Set['BasicBlock'] = set()
        self.successors: Set['BasicBlock'] = set()

    def __repr__(self):
        return f'BasicBlock({self.label})'

class CFG:
    def __init__(self, function: Function):
        self.function = function
        self.blocks: Dict[str, BasicBlock] = {}
        self.entry_block: BasicBlock = self.construct_cfg()

    def construct_cfg(self) -> BasicBlock:
        """
        Constructs the CFG for the function and returns the entry block.
        """
        # TODO: Implement CFG construction logic
        # Steps:
        # 1. Divide instructions into basic blocks.
        # 2. Establish successor and predecessor relationships.
        # 3. Handle labels and control flow instructions.
        
        if not self.function.instrs:
            # Empty function, create a single empty block
            entry = BasicBlock("entry")
            self.blocks["entry"] = entry
            return entry
        
        # Step 1: Identify block leaders
        leaders = self._identify_leaders()
        
        # Step 2: Partition instructions into basic blocks
        self._create_blocks(leaders)
        
        # Step 3: Establish control flow edges
        self._connect_blocks()
        
        # Return the entry block (first block)
        entry_label = next(iter(self.blocks.keys()))
        return self.blocks[entry_label]
    
    def _identify_leaders(self) -> Set[int]:
        """
        Identifies the indices of instructions that are leaders (start of basic blocks).
        Leaders are:
        1. The first instruction
        2. Any instruction that is a label
        3. Any instruction immediately after a control flow instruction (jmp, br, ret)
        """
        leaders = {0}  # First instruction is always a leader
        
        for i, instr in enumerate(self.function.instrs):
            # Label instructions are leaders
            if isinstance(instr, Label):
                leaders.add(i)
            
            # Check if instruction is a control flow operation
            if hasattr(instr, 'op') and instr.op:
                if instr.op in ['jmp', 'br', 'ret']:
                    # Instruction after control flow is a leader
                    if i + 1 < len(self.function.instrs):
                        leaders.add(i + 1)
        
        return leaders
    
    def _create_blocks(self, leaders: Set[int]):
        """
        Creates basic blocks and assigns instructions to them.
        """
        leader_list = sorted(leaders)
        
        for i, leader_idx in enumerate(leader_list):
            # Determine the range of instructions for this block
            start_idx = leader_idx
            end_idx = leader_list[i + 1] if i + 1 < len(leader_list) else len(self.function.instrs)
            
            # Get the label for this block
            first_instr = self.function.instrs[start_idx]
            if isinstance(first_instr, Label):
                block_label = first_instr.label
                # Skip the label instruction itself when adding to block
                block_instrs = self.function.instrs[start_idx + 1:end_idx]
            else:
                # Generate a label if the block doesn't start with one
                block_label = f"b{start_idx}"
                block_instrs = self.function.instrs[start_idx:end_idx]
            
            # Create the block
            block = BasicBlock(block_label)
            block.instructions = block_instrs
            self.blocks[block_label] = block
    
    def _connect_blocks(self):
        """
        Establishes successor and predecessor relationships between blocks.
        """
        block_list = list(self.blocks.values())
        
        for i, block in enumerate(block_list):
            # Check the last instruction of the block
            if not block.instructions:
                # Empty block, connect to next block if exists
                if i + 1 < len(block_list):
                    next_block = block_list[i + 1]
                    self._add_edge(block, next_block)
                continue
            
            last_instr = block.instructions[-1]
            
            # Handle control flow instructions
            if hasattr(last_instr, 'op') and last_instr.op:
                if last_instr.op == 'jmp':
                    # Unconditional jump to a label
                    target_label = last_instr.labels[0]
                    if target_label in self.blocks:
                        self._add_edge(block, self.blocks[target_label])
                
                elif last_instr.op == 'br':
                    # Conditional branch to two labels
                    then_label = last_instr.labels[0]
                    else_label = last_instr.labels[1]
                    if then_label in self.blocks:
                        self._add_edge(block, self.blocks[then_label])
                    if else_label in self.blocks:
                        self._add_edge(block, self.blocks[else_label])
                
                elif last_instr.op == 'ret':
                    # Return has no successors
                    pass
                
                else:
                    # Not a terminator, fall through to next block
                    if i + 1 < len(block_list):
                        next_block = block_list[i + 1]
                        self._add_edge(block, next_block)
            else:
                # No control flow instruction, fall through to next block
                if i + 1 < len(block_list):
                    next_block = block_list[i + 1]
                    self._add_edge(block, next_block)
    
    def _add_edge(self, from_block: BasicBlock, to_block: BasicBlock):
        """
        Adds an edge from from_block to to_block in the CFG.
        """
        from_block.successors.add(to_block)
        to_block.predecessors.add(from_block)

    def get_blocks(self) -> List[BasicBlock]:
        return list(self.blocks.values())