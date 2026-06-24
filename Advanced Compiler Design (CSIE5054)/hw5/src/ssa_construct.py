from typing import Dict, List, Set
from bril import Function, Instruction
from cfg import CFG, BasicBlock
from dominance import DominatorTree

def construct_ssa(function: Function):
    """
    Transforms the function into SSA form.
    """
    cfg = CFG(function)
    dom_tree = DominatorTree(cfg)

    # Step 1: Variable Definition Analysis
    def_blocks = collect_definitions(cfg, function)

    # Step 2: Insert φ-Functions
    insert_phi_functions(cfg, dom_tree, def_blocks, function)

    # Step 3: Rename Variables
    rename_variables(cfg, dom_tree, function)

    # After transformation, update the function's instructions
    function.instrs = reconstruct_instructions(cfg)

def collect_definitions(cfg: CFG, function: Function) -> Dict[str, Set[BasicBlock]]:
    """
    Collects the set of basic blocks in which each variable is defined.
    """
    # TODO: Implement variable definition collection
    def_blocks: Dict[str, Set[BasicBlock]] = {}
    
    # Handle function arguments - treat them as defined in the entry block
    if hasattr(function, 'args') and function.args:
        for arg in function.args:
            arg_name = arg.get('name') if isinstance(arg, dict) else arg.name
            if arg_name not in def_blocks:
                def_blocks[arg_name] = set()
            def_blocks[arg_name].add(cfg.entry_block)
    
    # Iterate over all blocks in the CFG
    for block in cfg.blocks.values():
        # Iterate over all instructions in the block
        for instr in block.instructions:
            # Check if the instruction defines a variable
            # This includes regular instructions with 'dest' and phi functions
            if isinstance(instr, dict):
                # Dictionary-based instruction (like phi functions we create)
                if 'dest' in instr and instr['dest']:
                    var = instr['dest']
                    if var not in def_blocks:
                        def_blocks[var] = set()
                    def_blocks[var].add(block)
            elif hasattr(instr, 'dest') and instr.dest:
                # Regular Bril instruction object with dest attribute
                var = instr.dest
                if var not in def_blocks:
                    def_blocks[var] = set()
                def_blocks[var].add(block)
    
    return def_blocks

def get_var_type(cfg: CFG, var: str, function: Function = None):
    """
    Get the type of a variable by finding its first definition.
    """
    # Check function arguments first
    if function and hasattr(function, 'args') and function.args:
        for arg in function.args:
            arg_name = arg.get('name') if isinstance(arg, dict) else getattr(arg, 'name', None)
            if arg_name == var:
                arg_type = arg.get('type') if isinstance(arg, dict) else getattr(arg, 'type', None)
                if arg_type:
                    return arg_type
    
    # Check instruction definitions
    for block in cfg.blocks.values():
        for instr in block.instructions:
            if isinstance(instr, dict):
                if instr.get('dest') == var and 'type' in instr:
                    return instr['type']
            elif hasattr(instr, 'dest') and instr.dest == var:
                if hasattr(instr, 'type') and instr.type:
                    return instr.type
    return None  # Type not found

def insert_phi_functions(cfg: CFG, dom_tree: DominatorTree, def_blocks: Dict[str, Set[BasicBlock]], function: Function = None):
    """
    Inserts φ-functions into the basic blocks.
    """
    # Track which blocks have phi functions for which variables
    phi_blocks: Dict[str, Set[BasicBlock]] = {var: set() for var in def_blocks}
    
    # Process each variable
    for var, def_set in def_blocks.items():
        # Get the type of this variable
        var_type = get_var_type(cfg, var, function)
        
        # Initialize worklist with all blocks where var is defined
        worklist = list(def_set)
        
        while worklist:
            block = worklist.pop(0)
            
            # For each block Y in the dominance frontier of block
            for df_block in dom_tree.dom_frontiers.get(block, set()):
                # If we haven't already inserted a phi function for var at df_block
                if df_block not in phi_blocks[var]:
                    # Insert phi function for var at the beginning of df_block
                    # Handle entry block specially - it has an implicit entry predecessor
                    if df_block == cfg.entry_block:
                        # Entry block with back-edges: add implicit "entry" predecessor
                        labels = ['__entry'] + [pred.label for pred in df_block.predecessors]
                        args = [var] * len(labels)
                    else:
                        labels = [pred.label for pred in df_block.predecessors]
                        args = [var] * len(labels)
                    
                    # Create a phi instruction
                    phi_instr = {
                        'op': 'phi',
                        'dest': var,
                        'labels': labels,
                        'args': args  # Placeholder args
                    }
                    
                    # Add type if available
                    if var_type:
                        phi_instr['type'] = var_type
                    
                    # Insert at the beginning of the block
                    df_block.instructions.insert(0, phi_instr)
                    
                    # Mark that we've added a phi function for var at df_block
                    phi_blocks[var].add(df_block)
                    
                    # If df_block wasn't originally a definition block, add it to worklist
                    if df_block not in def_set:
                        worklist.append(df_block)

def rename_variables(cfg: CFG, dom_tree: DominatorTree, function: Function = None):
    """
    Renames variables to ensure each assignment is unique.
    """
    # TODO: Implement variable renaming
    # Count[X]: Next available subscript for variable X
    count: Dict[str, int] = {}
    
    # Stack[X]: Stack holding subscripts assigned to X in current dominator path
    # For function arguments, we use None to indicate "use original name"
    stack: Dict[str, List] = {}
    
    # Initialize stack for function arguments
    if function and hasattr(function, 'args') and function.args:
        for arg in function.args:
            arg_name = arg.get('name') if isinstance(arg, dict) else getattr(arg, 'name', None)
            if arg_name:
                stack[arg_name] = [None]  # None means use original name (no subscript)
                count[arg_name] = 0
    
    def get_new_name(var: str, subscript) -> str:
        """Generate a new SSA name for a variable."""
        if subscript is None:
            return var  # Function argument, use original name
        return f"{var}.{subscript}"
    
    def rename_block(block: BasicBlock):
        """Recursively rename variables in a block and its dominator tree children."""
        local_defs = []  # Track (variable, count) pairs defined in this block
        
        # Special handling for entry block: update __entry phi arguments before processing
        if block == cfg.entry_block:
            for instr in block.instructions:
                if isinstance(instr, dict) and instr.get('op') == 'phi':
                    labels = instr.get('labels', [])
                    args = instr.get('args', [])
                    for i, label in enumerate(labels):
                        if label == '__entry':
                            # Use the current value from stack (for args, this is None = original name)
                            var = args[i]
                            base_var = var.split('.')[0] if '.' in var else var
                            if base_var in stack and stack[base_var]:
                                args[i] = get_new_name(base_var, stack[base_var][-1])
                    instr['args'] = args
        
        # 1. Process statements in block
        for instr in block.instructions:
            # Handle phi functions
            if isinstance(instr, dict) and instr.get('op') == 'phi':
                # Phi functions: only process definition, uses handled in step 2
                var = instr['dest']
                
                # Initialize data structures if needed
                if var not in count:
                    count[var] = 0
                    stack[var] = []
                
                # Replace definition with new subscript
                subscript = count[var]
                stack[var].append(subscript)
                count[var] += 1
                instr['dest'] = get_new_name(var, subscript)
                local_defs.append(var)
                
            else:
                # Regular instruction: replace uses first, then definitions
                
                # Replace uses with current subscript
                if hasattr(instr, 'args') and instr.args:
                    new_args = []
                    for arg in instr.args:
                        if arg in stack and stack[arg]:
                            new_args.append(get_new_name(arg, stack[arg][-1]))
                        else:
                            # Not a variable we're tracking (might be constant or undefined)
                            new_args.append(arg)
                    instr.args = new_args
                
                # Replace definitions with new subscript
                if hasattr(instr, 'dest') and instr.dest:
                    var = instr.dest
                    
                    # Initialize data structures if needed
                    if var not in count:
                        count[var] = 0
                        stack[var] = []
                    
                    subscript = count[var]
                    stack[var].append(subscript)
                    count[var] += 1
                    instr.dest = get_new_name(var, subscript)
                    local_defs.append(var)
        
        # 2. Process phi-functions in successor blocks
        for succ_block in block.successors:
            for instr in succ_block.instructions:
                if isinstance(instr, dict) and instr.get('op') == 'phi':
                    # Find which operand corresponds to the current block
                    labels = instr.get('labels', [])
                    args = instr.get('args', [])
                    
                    for i, label in enumerate(labels):
                        if label == block.label:
                            # Update the i-th operand
                            var = args[i]
                            # Extract base variable name (remove any existing subscript)
                            base_var = var.split('.')[0] if '.' in var else var
                            
                            if base_var in stack and stack[base_var]:
                                args[i] = get_new_name(base_var, stack[base_var][-1])
                            # If stack is empty, variable might be undefined on this path
                    
                    instr['args'] = args
        
        # 3. Recursively call Rename on dominator tree children
        for child_block in cfg.blocks.values():
            if dom_tree.idom.get(child_block) == block and child_block != block:
                rename_block(child_block)
        
        # 4. Clean up the stack for local variables
        for var in local_defs:
            if var in stack and stack[var]:
                stack[var].pop()
    
    # Start renaming from the entry block
    rename_block(cfg.entry_block)

def reconstruct_instructions(cfg: CFG) -> List[Instruction]:
    """
    Reconstructs the instruction list from the CFG after SSA transformation.
    """
    # TODO: Implement instruction reconstruction
    from bril import Label, ValueOperation
    
    instructions = []
    
    # Walk through blocks in order (using the dictionary order, which preserves insertion order)
    for block_label, block in cfg.blocks.items():
        # Add a label for this block
        label_instr = Label({'label': block_label})
        instructions.append(label_instr)
        
        # Add all instructions from this block
        for instr in block.instructions:
            if isinstance(instr, dict):
                # Dictionary-based instruction (like phi functions)
                # Convert to proper Instruction object
                if instr.get('op') == 'phi':
                    # Create a ValueOperation for phi
                    phi_instr = ValueOperation(instr)
                    instructions.append(phi_instr)
                else:
                    # Other dictionary-based instructions
                    from bril import Const, EffectOperation
                    if instr.get('op') == 'const':
                        instructions.append(Const(instr))
                    elif 'dest' in instr:
                        instructions.append(ValueOperation(instr))
                    else:
                        instructions.append(EffectOperation(instr))
            else:
                # Regular Instruction object
                instructions.append(instr)
    
    return instructions