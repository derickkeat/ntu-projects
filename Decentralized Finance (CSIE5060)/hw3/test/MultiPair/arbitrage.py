import networkx as nx
import itertools

class ArbitragePathFinder:
    def __init__(self, pools):
        """
        Initialize with liquidity pools configuration
        
        :param pools: Dict of pools with token pairs and their reserves
        Example: {
            ('A', 'B'): {'reserve_0': 17, 'reserve_1': 10, 'fee': 0.003},
            ('A', 'C'): {'reserve_0': 11, 'reserve_1': 7, 'fee': 0.003}
        }
        """
        self.graph = nx.DiGraph()
        self.pools = pools
        self._build_graph()
    
    def _build_graph(self):
        """Construct directed graph from pools"""
        for (token1, token2), pool_data in self.pools.items():
            # Forward edge
            input_amount = pool_data['reserve_0']
            output_amount = pool_data['reserve_1']
            swap_fee = pool_data['fee']
            
            net_output = output_amount * (1 - swap_fee)
            self.graph.add_edge(token1, token2, 
                                weight=-net_output/input_amount, 
                                pool=(token1, token2))
            
            # Reverse edge
            input_amount = pool_data['reserve_1']
            output_amount = pool_data['reserve_0']
            net_output = output_amount * (1 - swap_fee)
            self.graph.add_edge(token2, token1, 
                                weight=-net_output/input_amount, 
                                pool=(token2, token1))
    
    def find_arbitrage_paths(self, start_token, target_token, max_hops=3):
        """
        Find potential arbitrage paths
        
        :param start_token: Starting token
        :param target_token: Desired output token
        :param max_hops: Maximum number of swaps
        :return: List of profitable paths
        """
        paths = []
        for hop_count in range(2, max_hops + 1):
            for path in nx.all_simple_paths(self.graph, start_token, target_token, cutoff=hop_count):
                # Compute path profitability
                path_profit = self._calculate_path_profit(path)
                if path_profit > 1:  # Profitable path
                    paths.append({
                        'path': path,
                        'profit_ratio': path_profit
                    })
        return sorted(paths, key=lambda x: x['profit_ratio'], reverse=True)
    
    def _calculate_path_profit(self, path):
        """
        Calculate total path profit considering swap fees
        
        :param path: Token swap path
        :return: Profit ratio (> 1 means profitable)
        """
        total_profit = 1.0
        for i in range(len(path) - 1):
            forward_pool = (path[i], path[i+1])
            pool_data = next((
                data for k, data in self.pools.items() 
                if set(k) == set(forward_pool)
            ), None)
            
            if not pool_data:
                return 0
            
            swap_fee = pool_data['fee']
            total_profit *= (1 - swap_fee)
        
        return total_profit

# Example Usage
pools = {
    ('A', 'B'): {'reserve_0': 17, 'reserve_1': 10, 'fee': 0.003},
    ('A', 'C'): {'reserve_0': 11, 'reserve_1': 7, 'fee': 0.003},
    ('A', 'D'): {'reserve_0': 15, 'reserve_1': 9, 'fee': 0.003},
    ('A', 'E'): {'reserve_0': 21, 'reserve_1': 5, 'fee': 0.003},
    ('B', 'C'): {'reserve_0': 36, 'reserve_1': 4, 'fee': 0.003},
    ('B', 'D'): {'reserve_0': 16, 'reserve_1': 6, 'fee': 0.003},
    ('B', 'E'): {'reserve_0': 25, 'reserve_1': 3, 'fee': 0.003},
    ('C', 'D'): {'reserve_0': 30, 'reserve_1': 12, 'fee': 0.003},
    ('C', 'E'): {'reserve_0': 10, 'reserve_1': 8, 'fee': 0.003},
    ('D', 'E'): {'reserve_0': 60, 'reserve_1': 25, 'fee': 0.003},
    # Add more pools from the test contract
}

finder = ArbitragePathFinder(pools)
arbitrage_paths = finder.find_arbitrage_paths('B', 'B')
print("Potential Arbitrage Paths:", arbitrage_paths)