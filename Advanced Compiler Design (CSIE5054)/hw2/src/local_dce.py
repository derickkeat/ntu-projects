import sys
import json
from form_blocks import form_blocks
from util import flatten


def trivial_dce_pass(func):
    """
    TODO:
    1. Remove instructions from func that are never used as arguments to any other instruction.
    2. Return a bool indicating whether anything changed.
    """
    used = set()
    changed = False
    for instr in func['instrs']:
        if 'args' in instr:
            used.update(instr.get('args', []))
        if 'value' in instr:
            used.add(instr.get('value', ''))
    for instr in func['instrs']:
        if 'dest' in instr and instr.get('dest', '') not in used:
            func['instrs'].remove(instr)
            changed = True
    return changed



def drop_killed_local(block):
    """
    TODO:
    1. Delete instructions in a single block whose result is unused before the next assignment. 
    2. Return a bool indicating whether anything changed.
    """
    last_def = {}
    change = False
    for instr in block:
        if 'dest' in instr and instr.get('dest', '') not in last_def:
            last_def[instr.get('dest', '')] = instr
        elif 'dest' in instr and instr.get('dest', '') in last_def:
            block.remove(last_def[instr.get('dest', '')])
            last_def[instr.get('dest', '')] = instr
            change = True
    return change


def drop_killed_pass(func):
    """Drop killed functions from *all* blocks. Return a bool indicating
    whether anything changed.
    """
    blocks = list(form_blocks(func['instrs']))
    changed = False
    for block in blocks:
        changed |= drop_killed_local(block)
    func['instrs'] = flatten(blocks)
    return changed


def trivial_dce_plus(func):
    while trivial_dce_pass(func) or drop_killed_pass(func):
        pass




def localopt():
    modify_func = trivial_dce_plus
    # Apply the change to all the functions in the input program.
    bril = json.load(sys.stdin)
    for func in bril['functions']:
        modify_func(func)
    json.dump(bril, sys.stdout, indent=2, sort_keys=True)


if __name__ == '__main__':
    localopt()
