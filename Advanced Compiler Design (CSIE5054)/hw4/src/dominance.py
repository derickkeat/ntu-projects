from typing import Dict, Set
from functools import reduce
from cfg import CFG, BasicBlock

class DominatorTree:
    def __init__(self, cfg: CFG):
        self.cfg = cfg
        self.dom: Dict[BasicBlock, Set[BasicBlock]] = {}
        self.idom: Dict[BasicBlock, BasicBlock] = {}
        self.dom_frontiers: Dict[BasicBlock, Set[BasicBlock]] = {}
        self.compute_dominators()
        self.compute_idom()
        self.compute_dominance_frontiers()

    def compute_dominators(self):
        """
        Computes the dominators for each basic block.
        """
        # TODO: Implement the iterative algorithm to compute dominators.
        all_blocks = set(self.cfg.blocks.values())
        
        # Initialize: entry dominates only itself, others dominate all
        self.dom = {}
        self.dom[self.cfg.entry_block] = {self.cfg.entry_block}
        for block in self.cfg.blocks.values():
            if block != self.cfg.entry_block:
                self.dom[block] = all_blocks.copy()
        
        # Iterate until fixed point
        changed = True
        while changed:
            changed = False
            for block in self.cfg.blocks.values():
                if block == self.cfg.entry_block:
                    continue
                
                # New dominators = {block} ∪ (∩ dom(pred) for all predecessors)
                if block.predecessors:
                    new_dom = {block} | reduce(
                        set.intersection,
                        [self.dom[pred] for pred in block.predecessors]
                    )
                else:
                    new_dom = {block}
                
                if new_dom != self.dom[block]:
                    self.dom[block] = new_dom
                    changed = True

    def compute_idom(self):
        """
        Computes the immediate dominator for each basic block.
        """
        # TODO: Compute immediate dominators based on the dominator sets.
        self.idom = {}
        self.idom[self.cfg.entry_block] = None  # Entry has no idom
        
        for block in self.cfg.blocks.values():
            if block == self.cfg.entry_block:
                continue
            
            # Get strict dominators (dominators excluding the block itself)
            strict_doms = self.dom[block] - {block}
            
            # Find the dominator with the largest dominator set (closest to block)
            # This is the immediate dominator
            if strict_doms:
                self.idom[block] = max(strict_doms, key=lambda x: len(self.dom[x]))

    def compute_dominance_frontiers(self):
        """
        Computes the dominance frontiers for each basic block.
        """
        # TODO: Implement dominance frontier computation.
        self.dom_frontiers = {block: set() for block in self.cfg.blocks.values()}
        
        for block in self.cfg.blocks.values():
            # Process blocks with multiple predecessors (join points)
            # Also process entry block with any predecessors (loop back-edges)
            num_preds = len(block.predecessors)
            is_entry_with_backedge = (block == self.cfg.entry_block and num_preds >= 1)
            
            if num_preds >= 2 or is_entry_with_backedge:
                for pred in block.predecessors:
                    runner = pred
                    # Walk up the dominator tree until we reach the idom of block
                    while runner and runner != self.idom.get(block):
                        self.dom_frontiers[runner].add(block)
                        runner = self.idom.get(runner)