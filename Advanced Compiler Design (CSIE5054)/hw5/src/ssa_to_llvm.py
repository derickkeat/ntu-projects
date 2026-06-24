from bril import Program, Function, Instruction, Label, Const, ValueOperation, EffectOperation
from typing import Dict, List, Set

class LLVMTranslator:
    """Translates Bril SSA programs to LLVM IR."""
    
    def __init__(self):
        self.type_map = {
            'int': 'i64',
            'bool': 'i1',
            'float': 'double'
        }
        self.llvm_lines = []
        self.var_types = {}  # Track variable types
        self.label_count = 0
        
    def bril_type_to_llvm(self, bril_type: str) -> str:
        """Convert Bril type to LLVM type."""
        if bril_type in self.type_map:
            return self.type_map[bril_type]
        return bril_type
    
    def sanitize_label(self, label: str) -> str:
        """Sanitize label names for LLVM."""
        # Handle special __entry label from SSA construction
        if label == '__entry':
            return 'entry'
        
        # Remove leading dots/dashes and replace internal ones with underscores
        sanitized = label.lstrip('.-').replace('.', '_').replace('-', '_')
        
        # Ensure it starts with a letter or underscore
        if sanitized and not (sanitized[0].isalpha() or sanitized[0] == '_'):
            sanitized = 'label_' + sanitized
        
        # If empty after stripping, use a default
        if not sanitized:
            sanitized = 'label_0'
            
        return sanitized
    
    def emit(self, line: str):
        """Add a line to the LLVM IR output."""
        self.llvm_lines.append(line)
    
    def translate_program(self, program: Program) -> str:
        """Translate the entire Bril program to LLVM IR."""
        # Emit runtime declarations
        self.emit_runtime_declarations()
        
        # Translate each function
        for function in program.functions:
            self.translate_function(function)
        
        return '\n'.join(self.llvm_lines)
    
    def emit_runtime_declarations(self):
        """Emit declarations for runtime functions like printf."""
        self.emit('; Runtime declarations')
        self.emit('declare i32 @printf(i8*, ...)')
        self.emit('declare i32 @puts(i8*)')
        self.emit('declare i64 @atol(i8*)')
        self.emit('')
        # Define format strings for printing
        self.emit('@.str_int = private unnamed_addr constant [5 x i8] c"%ld\\0A\\00", align 1')
        self.emit('@.str_true = private unnamed_addr constant [5 x i8] c"true\\00", align 1')
        self.emit('@.str_false = private unnamed_addr constant [6 x i8] c"false\\00", align 1')
        self.emit('')
    
    def translate_function(self, function: Function):
        """Translate a Bril function to LLVM IR."""
        self.var_types = {}
        self.entry_block_label = None
        
        # Special handling for main function with arguments
        if function.name == 'main' and function.args:
            self.translate_main_with_args(function)
            return
        
        # Special handling for main function without arguments (needs to return int for C compat)
        if function.name == 'main' and not function.args:
            self.translate_main_without_args(function)
            return
        
        # Build function signature
        return_type = 'void'
        if function.type:
            return_type = self.bril_type_to_llvm(function.type)
        
        # Process function arguments
        param_strs = []
        if function.args:
            for arg in function.args:
                arg_name = arg.get('name') if isinstance(arg, dict) else arg.name
                arg_type = arg.get('type') if isinstance(arg, dict) else arg.type
                llvm_type = self.bril_type_to_llvm(arg_type)
                self.var_types[arg_name] = llvm_type
                param_strs.append(f"{llvm_type} %{arg_name}")
        
        params = ', '.join(param_strs) if param_strs else ''
        
        # Emit function definition
        self.emit(f'define {return_type} @{function.name}({params}) {{')
        
        # First pass: collect all variable types
        self.collect_variable_types(function)
        
        # Check if first block needs an entry block
        needs_entry_block = self.check_needs_entry_block(function.instrs)
        
        if needs_entry_block:
            # Create an entry block that jumps to the first real block
            self.emit('entry:')
            # Find first label
            for instr in function.instrs:
                if isinstance(instr, Label):
                    first_label = self.sanitize_label(instr.label)
                    self.emit(f'  br label %{first_label}')
                    break
        
        # Translate instructions
        has_terminator = self.translate_instructions(function.instrs)
        
        # Ensure function has a return if the last block doesn't have one
        if not has_terminator:
            if function.type:
                # Function should return a value but doesn't - this is an error
                # For now, return undef
                self.emit(f'  ret {return_type} undef')
            else:
                self.emit('  ret void')
        
        self.emit('}')
        self.emit('')
    
    def translate_main_without_args(self, function: Function):
        """Translate main function without arguments - wrapper to return int."""
        # Create the actual Bril main function
        real_main_name = '__bril_main'
        
        # Emit the real function (void return)
        self.emit(f'define void @{real_main_name}() {{')
        
        # Collect variable types
        self.collect_variable_types(function)
        
        # Check if needs entry block
        needs_entry_block = self.check_needs_entry_block(function.instrs)
        
        if needs_entry_block:
            self.emit('entry:')
            for instr in function.instrs:
                if isinstance(instr, Label):
                    first_label = self.sanitize_label(instr.label)
                    self.emit(f'  br label %{first_label}')
                    break
        
        # Translate instructions
        has_terminator = self.translate_instructions(function.instrs)
        
        if not has_terminator:
            self.emit('  ret void')
        
        self.emit('}')
        self.emit('')
        
        # Create wrapper that returns int
        self.emit('define i32 @main() {')
        self.emit('  call void @__bril_main()')
        self.emit('  ret i32 0')
        self.emit('}')
        self.emit('')
    
    def translate_main_with_args(self, function: Function):
        """Translate main function with arguments - needs special handling for command-line args."""
        # Create the actual Bril main function with a different name
        real_main_name = '__bril_main'
        
        # Build real function signature
        return_type = 'void'
        if function.type:
            return_type = self.bril_type_to_llvm(function.type)
        
        # Process function arguments
        param_strs = []
        arg_types = []
        arg_names = []
        for arg in function.args:
            arg_name = arg.get('name') if isinstance(arg, dict) else arg.name
            arg_type = arg.get('type') if isinstance(arg, dict) else arg.type
            llvm_type = self.bril_type_to_llvm(arg_type)
            self.var_types[arg_name] = llvm_type
            param_strs.append(f"{llvm_type} %{arg_name}")
            arg_types.append(llvm_type)
            arg_names.append(arg_name)
        
        params = ', '.join(param_strs)
        
        # Emit the real function
        self.emit(f'define {return_type} @{real_main_name}({params}) {{')
        
        # Collect variable types
        self.collect_variable_types(function)
        
        # Check if needs entry block
        needs_entry_block = self.check_needs_entry_block(function.instrs)
        
        if needs_entry_block:
            self.emit('entry:')
            for instr in function.instrs:
                if isinstance(instr, Label):
                    first_label = self.sanitize_label(instr.label)
                    self.emit(f'  br label %{first_label}')
                    break
        
        # Translate instructions
        has_terminator = self.translate_instructions(function.instrs)
        
        if not has_terminator:
            if function.type:
                self.emit(f'  ret {return_type} undef')
            else:
                self.emit('  ret void')
        
        self.emit('}')
        self.emit('')
        
        # Now create the wrapper main function that parses command-line arguments
        self.emit('define i32 @main(i32 %argc, i8** %argv) {')
        
        # Parse each argument from argv
        for i, (arg_name, arg_type) in enumerate(zip(arg_names, arg_types)):
            # argv[i+1] (skip program name)
            self.emit(f'  %argv_ptr_{i} = getelementptr inbounds i8*, i8** %argv, i64 {i+1}')
            self.emit(f'  %argv_str_{i} = load i8*, i8** %argv_ptr_{i}')
            
            if arg_type == 'i64':
                # Convert string to int64 using atol
                self.emit(f'  %arg_{i} = call i64 @atol(i8* %argv_str_{i})')
            elif arg_type == 'i1':
                # For bool, convert string to int and check if non-zero
                self.emit(f'  %arg_{i}_int = call i64 @atol(i8* %argv_str_{i})')
                self.emit(f'  %arg_{i} = icmp ne i64 %arg_{i}_int, 0')
            else:
                # Default to i64
                self.emit(f'  %arg_{i} = call i64 @atol(i8* %argv_str_{i})')
        
        # Call the real main function
        call_args = ', '.join([f'{arg_type} %arg_{i}' for i, arg_type in enumerate(arg_types)])
        if return_type == 'void':
            self.emit(f'  call void @{real_main_name}({call_args})')
            self.emit('  ret i32 0')
        else:
            self.emit(f'  %result = call {return_type} @{real_main_name}({call_args})')
            if return_type == 'i64':
                self.emit('  %exit_code = trunc i64 %result to i32')
                self.emit('  ret i32 %exit_code')
            elif return_type == 'i1':
                self.emit('  %exit_code = zext i1 %result to i32')
                self.emit('  ret i32 %exit_code')
            else:
                self.emit('  ret i32 0')
        
        self.emit('}')
        self.emit('')
    
    def check_needs_entry_block(self, instrs: List[Instruction]) -> bool:
        """Check if the first block has phi nodes referencing an entry predecessor."""
        # Find first block
        found_first_label = False
        for instr in instrs:
            if isinstance(instr, Label):
                found_first_label = True
                continue
            
            if found_first_label:
                # Check if this instruction is a phi with entry reference
                if isinstance(instr, ValueOperation) and instr.op == 'phi':
                    labels = instr.labels if hasattr(instr, 'labels') else []
                    for label in labels:
                        if label == '__entry' or label == 'entry':
                            return True
                elif isinstance(instr, dict) and instr.get('op') == 'phi':
                    labels = instr.get('labels', [])
                    for label in labels:
                        if label == '__entry' or label == 'entry':
                            return True
                else:
                    # First non-label, non-phi instruction - no more phis
                    break
        
        return False
    
    def collect_variable_types(self, function: Function):
        """Collect types of all variables in the function."""
        for instr in function.instrs:
            if isinstance(instr, Label):
                continue
            
            # Get destination and type
            dest = None
            var_type = None
            
            if isinstance(instr, Const):
                dest = instr.dest
                var_type = instr.type
            elif isinstance(instr, ValueOperation):
                dest = instr.dest
                var_type = instr.type
            elif isinstance(instr, dict):
                dest = instr.get('dest')
                var_type = instr.get('type')
            
            if dest and var_type:
                self.var_types[dest] = self.bril_type_to_llvm(var_type)
    
    def translate_instructions(self, instrs: List[Instruction]) -> bool:
        """Translate a list of instructions. Returns True if last instruction is a terminator."""
        current_block_has_terminator = False
        in_block = False
        
        for i, instr in enumerate(instrs):
            if isinstance(instr, Label):
                # Emit block terminator if needed before starting new block
                if in_block and not current_block_has_terminator:
                    # Look ahead to find next block
                    next_label = self.sanitize_label(instr.label)
                    self.emit(f'  br label %{next_label}')
                
                # Start new basic block
                self.emit(f'{self.sanitize_label(instr.label)}:')
                current_block_has_terminator = False
                in_block = True
            else:
                result = self.translate_instruction(instr)
                if result:
                    self.emit(f'  {result}')
                
                # Check if this is a terminator instruction
                op = None
                if hasattr(instr, 'op'):
                    op = instr.op
                elif isinstance(instr, dict):
                    op = instr.get('op')
                
                if op in ['ret', 'br', 'jmp']:
                    current_block_has_terminator = True
        
        return current_block_has_terminator
    
    def translate_instruction(self, instr) -> str:
        """Translate a single instruction to LLVM IR."""
        # Handle dictionary-based instructions (like phi)
        if isinstance(instr, dict):
            op = instr.get('op')
            if op == 'phi':
                return self.translate_phi(instr)
            # Convert to object for uniform handling
            if op == 'const':
                instr = Const(instr)
            elif 'dest' in instr:
                instr = ValueOperation(instr)
            else:
                instr = EffectOperation(instr)
        
        if isinstance(instr, Const):
            return self.translate_const(instr)
        elif isinstance(instr, ValueOperation):
            return self.translate_value_op(instr)
        elif isinstance(instr, EffectOperation):
            return self.translate_effect_op(instr)
        
        return ''
    
    def translate_const(self, instr: Const) -> str:
        """Translate a const instruction."""
        dest = instr.dest
        value = instr.value
        llvm_type = self.var_types.get(dest, 'i64')
        
        # Handle boolean constants
        if llvm_type == 'i1':
            value = 1 if value else 0
        
        return f'%{dest} = add {llvm_type} 0, {value}'
    
    def translate_phi(self, instr: dict) -> str:
        """Translate a phi instruction."""
        dest = instr['dest']
        args = instr.get('args', [])
        labels = instr.get('labels', [])
        llvm_type = self.var_types.get(dest, 'i64')
        
        # Build phi node
        phi_parts = []
        for arg, label in zip(args, labels):
            sanitized_label = self.sanitize_label(label)
            # Check if the argument appears to be undefined (no SSA subscript)
            if '.' not in arg and arg not in self.var_types:
                phi_parts.append(f'[ undef, %{sanitized_label} ]')
            else:
                phi_parts.append(f'[ %{arg}, %{sanitized_label} ]')
        
        phi_str = ', '.join(phi_parts)
        return f'%{dest} = phi {llvm_type} {phi_str}'
    
    def translate_value_op(self, instr: ValueOperation) -> str:
        """Translate a value operation (instruction that produces a value)."""
        op = instr.op
        dest = instr.dest
        args = instr.args if hasattr(instr, 'args') else []
        llvm_type = self.var_types.get(dest, 'i64')
        
        # Phi operation
        if op == 'phi':
            labels = instr.labels if hasattr(instr, 'labels') else []
            # Build phi node
            phi_parts = []
            for arg, label in zip(args, labels):
                sanitized_label = self.sanitize_label(label)
                # Check if the argument appears to be undefined (no SSA subscript)
                # Variables without subscripts (like 'x' instead of 'x.0') are likely undefined
                # unless they're in var_types (function params or defined variables)
                if '.' not in arg and arg not in self.var_types:
                    # Use undef for undefined variables
                    phi_parts.append(f'[ undef, %{sanitized_label} ]')
                else:
                    phi_parts.append(f'[ %{arg}, %{sanitized_label} ]')
            phi_str = ', '.join(phi_parts)
            return f'%{dest} = phi {llvm_type} {phi_str}'
        
        # Arithmetic operations
        if op == 'add':
            return f'%{dest} = add {llvm_type} %{args[0]}, %{args[1]}'
        elif op == 'sub':
            return f'%{dest} = sub {llvm_type} %{args[0]}, %{args[1]}'
        elif op == 'mul':
            return f'%{dest} = mul {llvm_type} %{args[0]}, %{args[1]}'
        elif op == 'div':
            return f'%{dest} = sdiv {llvm_type} %{args[0]}, %{args[1]}'
        elif op == 'mod':
            return f'%{dest} = srem {llvm_type} %{args[0]}, %{args[1]}'
        
        # Comparison operations
        elif op == 'eq':
            arg_type = self.var_types.get(args[0], 'i64')
            return f'%{dest} = icmp eq {arg_type} %{args[0]}, %{args[1]}'
        elif op == 'ne':
            arg_type = self.var_types.get(args[0], 'i64')
            return f'%{dest} = icmp ne {arg_type} %{args[0]}, %{args[1]}'
        elif op == 'lt':
            arg_type = self.var_types.get(args[0], 'i64')
            return f'%{dest} = icmp slt {arg_type} %{args[0]}, %{args[1]}'
        elif op == 'le':
            arg_type = self.var_types.get(args[0], 'i64')
            return f'%{dest} = icmp sle {arg_type} %{args[0]}, %{args[1]}'
        elif op == 'gt':
            arg_type = self.var_types.get(args[0], 'i64')
            return f'%{dest} = icmp sgt {arg_type} %{args[0]}, %{args[1]}'
        elif op == 'ge':
            arg_type = self.var_types.get(args[0], 'i64')
            return f'%{dest} = icmp sge {arg_type} %{args[0]}, %{args[1]}'
        
        # Logical operations
        elif op == 'and':
            return f'%{dest} = and {llvm_type} %{args[0]}, %{args[1]}'
        elif op == 'or':
            return f'%{dest} = or {llvm_type} %{args[0]}, %{args[1]}'
        elif op == 'not':
            return f'%{dest} = xor {llvm_type} %{args[0]}, 1'
        
        # Identity operation
        elif op == 'id':
            return f'%{dest} = add {llvm_type} 0, %{args[0]}'
        
        # Call operation
        elif op == 'call':
            func_name = instr.funcs[0] if hasattr(instr, 'funcs') and instr.funcs else 'unknown'
            arg_strs = []
            for arg in args:
                arg_type = self.var_types.get(arg, 'i64')
                arg_strs.append(f'{arg_type} %{arg}')
            args_str = ', '.join(arg_strs)
            return f'%{dest} = call {llvm_type} @{func_name}({args_str})'
        
        return f'; Unknown value operation: {op}'
    
    def translate_effect_op(self, instr: EffectOperation) -> str:
        """Translate an effect operation (instruction with side effects)."""
        op = instr.op
        args = instr.args if hasattr(instr, 'args') else []
        labels = instr.labels if hasattr(instr, 'labels') else []
        
        # Branch operations
        if op == 'br':
            # Conditional branch
            cond = args[0]
            then_label = self.sanitize_label(labels[0])
            else_label = self.sanitize_label(labels[1])
            return f'br i1 %{cond}, label %{then_label}, label %{else_label}'
        
        elif op == 'jmp':
            # Unconditional jump
            target_label = self.sanitize_label(labels[0])
            return f'br label %{target_label}'
        
        elif op == 'ret':
            # Return statement
            if args:
                arg = args[0]
                arg_type = self.var_types.get(arg, 'i64')
                return f'ret {arg_type} %{arg}'
            else:
                return 'ret void'
        
        # Print operation
        elif op == 'print':
            if args:
                arg = args[0]
                arg_type = self.var_types.get(arg, 'i64')
                
                if arg_type == 'i1':
                    # Print boolean as "true" or "false"
                    temp_var = f'{arg.replace(".", "_")}_str'
                    self.emit(f'  %{temp_var} = select i1 %{arg}, i8* getelementptr inbounds ([5 x i8], [5 x i8]* @.str_true, i64 0, i64 0), i8* getelementptr inbounds ([6 x i8], [6 x i8]* @.str_false, i64 0, i64 0)')
                    return f'call i32 @puts(i8* %{temp_var})'
                else:
                    # Print integer or other types
                    return f'call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([5 x i8], [5 x i8]* @.str_int, i64 0, i64 0), {arg_type} %{arg})'
            return ''
        
        # Nop operation
        elif op == 'nop':
            return '; nop'
        
        # Call operation (without return value)
        elif op == 'call':
            func_name = instr.funcs[0] if hasattr(instr, 'funcs') and instr.funcs else 'unknown'
            arg_strs = []
            for arg in args:
                arg_type = self.var_types.get(arg, 'i64')
                arg_strs.append(f'{arg_type} %{arg}')
            args_str = ', '.join(arg_strs)
            return f'call void @{func_name}({args_str})'
        
        return f'; Unknown effect operation: {op}'


def bril_to_llvm(program: Program) -> str:
    """
    Translate a Bril program in SSA form to LLVM IR.

    Args:
        program (Program): The Bril program represented as a Program object.

    Returns:
        str: The generated LLVM IR code as a string.
    """
    translator = LLVMTranslator()
    return translator.translate_program(program)