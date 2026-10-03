import numpy as np
import random
from typing import List, Tuple, Optional

class GeneticAlgorithm:
    def __init__(
        self,
        pop_size: int,      # Population size
        generations: int,   # Number of generations for the algorithm
        mutation_rate: float,  # Gene mutation rate
        crossover_rate: float,  # Gene crossover rate
        tournament_size: int,  # Tournament size for selection
        elitism: bool,         # Whether to apply elitism strategy
        random_seed: Optional[int],  # Random seed for reproducibility
    ):
        # Students need to set the algorithm parameters
        self.pop_size = pop_size
        self.generations = generations
        self.mutation_rate = mutation_rate
        self.crossover_rate = crossover_rate
        self.tournament_size = tournament_size
        self.elitism = elitism

        if random_seed is not None:
            random.seed(random_seed)
            np.random.seed(random_seed)

    def _init_population(self, M: int, N: int) -> List[List[int]]:
        """
        Initialize the population and generate random individuals, ensuring that every student is assigned at least one task.
        :param M: Number of students
        :param N: Number of tasks
        :return: Initialized population
        """
        # TODO: Initialize individuals based on the number of students M and number of tasks N
        population = []

        # assign task to each student, 
        # index = task, value = student
        # append each individual into population
        for _ in range(self.pop_size):
            individual = [random.randint(0, M - 1) for _ in range(N)]

            for student in range(M):
                if student not in individual:
                    individual[random.randint(0, N - 1)] = student

            population.append(individual)

        return population

    def _fitness(self, individual: List[int], student_times: np.ndarray) -> float:
        """
        Fitness function: calculate the fitness value of an individual.
        :param individual: Individual
        :param student_times: Time required for each student to complete each task
        :return: Fitness value
        """
        # TODO: Design a fitness function to compute the fitness value of the allocation plan
        # make an array that has the length of total student
        student_workloads = np.zeros(len(student_times))

        # calculate the time cost for each student
        for task, student in enumerate(individual): # enumerate(individual) = (task, student)
            student_workloads[student] += student_times[student][task] # student_times is cost
        
        # fitness is the inverse of maximum time
        max_time = np.max(student_workloads)
        return 1.0 / max_time

    def _selection(self, population: List[List[int]], fitness_scores: List[float]) -> List[int]:
        """
        Use tournament selection to choose parents for crossover.
        :param population: Current population
        :param fitness_scores: Fitness scores for each individual
        :return: Selected parent
        """
        # TODO: Use tournament selection to choose parents based on fitness scores
        # randomly choose from population -> a list with length of tournament_size
        tournament = random.sample(range(len(population)), self.tournament_size)
        # fitness of the selected population
        tournament_fitness = [fitness_scores[i] for i in tournament]
        # getting the most fit individual
        winner = tournament[tournament_fitness.index(max(tournament_fitness))]

        # the above are just index of population, so we returning like this
        return population[winner]

    def _crossover(self, parent1: List[int], parent2: List[int], M: int) -> Tuple[List[int], List[int]]:
        """
        Crossover: generate two offspring from two parents.
        :param parent1: Parent 1
        :param parent2: Parent 2
        :param M: Number of students
        :return: Generated offspring
        """
        # TODO: Complete the crossover operation to generate two offspring
        # check if successfully crossover
        if random.random() > self.crossover_rate:
            return parent1.copy(), parent2.copy()

        # number of tasks
        N = len(parent1)

        point1, point2 = sorted(random.sample(range(N), 2))

        offspring1 = parent1[:point1] + parent2[point1: point2] + parent1[point2:]
        offspring2 = parent2[:point1] + parent1[point1: point2] + parent2[point2:]

        # index = tasks, value = students
        for offspring in [offspring1, offspring2]:
            # set(range(M)) will have all students
            missing_students = set(range(M)) - set(offspring)
            for student in missing_students:
                offspring[random.randint(0, N - 1)] = student
        
        return offspring1, offspring2

    def _mutate(self, individual: List[int], M: int) -> List[int]:
        """
        Mutation operation: randomly change some genes (task assignments) of the individual.
        :param individual: Individual
        :param M: Number of students
        :return: Mutated individual
        """
        # TODO: Implement the mutation operation to randomly modify genes
        # index = tasks, value = students
        mutated = individual.copy()

        for i in range(len(mutated)):
            if random.random() > self.mutation_rate:
                mutated[i] = random.randint(0, M - 1)
        
        for student in range(M):
            if student not in mutated:
                mutated[random.randint(0, len(mutated) - 1)] = student
        
        return mutated

    def __call__(self, M: int, N: int, student_times: np.ndarray) -> Tuple[List[int], int]:
        """
        Execute the genetic algorithm and return the optimal solution (allocation plan) and its total time cost.
        :param M: Number of students
        :param N: Number of tasks
        :param student_times: Time required for each student to complete each task
        :return: Optimal allocation plan and total time cost
        """
        # TODO: Complete the genetic algorithm process, including initialization, selection, crossover, mutation, and elitism strategy
        population = self._init_population(M, N)
        best_fitness = 0.0
        best_solution = None

        for _ in range(self.generations):
            fitness_scores = [self._fitness(ind, student_times) for ind in population]
            
            if max(fitness_scores) > best_fitness:
                best_fitness = max(fitness_scores)
                best_solution = population[fitness_scores.index(max(fitness_scores))]
            
            new_population = []

            # if elitism is enabled, put the best solution in next gen
            if self.elitism:
                new_population.append(best_solution)

            # making offspring and mutate the offspring
            while len(new_population) < self.pop_size:
                parent1 = self._selection(population, fitness_scores)
                parent2 = self._selection(population, fitness_scores)

                offspring1, offspring2 = self._crossover(parent1, parent2, M)

                offspring1 = self._mutate(offspring1, M)
                offspring2 = self._mutate(offspring2, M)

                new_population.append(offspring1)
                new_population.append(offspring2)
            
            # since the above code adds two offspring at a time, there might be chance where there is more offspring
            population = new_population.copy()
            if len(population) > self.pop_size:
                population.pop()

        student_jobs = np.zeros(N)
        for task, student in enumerate(best_solution):
            student_jobs[task] = student_times[student][task]
        
        total_time = int(np.sum(student_jobs))

        return best_solution, total_time


if __name__ == "__main__":
    def write_output_to_file(problem_num: int, total_time: int, filename: str = "results.txt") -> None:
        """
        Write results to a file and check if the format is correct.
        """
        print(f"Problem {problem_num}: Total time = {total_time}")

        if not isinstance(total_time, int) :
            raise ValueError(f"Invalid format for problem {problem_num}. Total time should be an integer.")
        
        with open(filename, 'a') as file:
            file.write(f"Total time = {total_time}\n")

    # TODO: Define multiple test problems based on the examples and solve them using the genetic algorithm
    # Example problem 1 (define multiple problems based on the given example format)
    # M, N = 2, 3
    # student_times = [[3, 8, 6],
    #                  [5, 2, 7]]


    ### Test Case

    # M1, N1 = 5,5
    # cost1 = [[8,8,4,1,2],
    #          [5,2,6,6,2],
    #          [7,10,2,1,5],
    #          [1,3,2,7,7],
    #          [8,11,9,8,9]]

    # M2, N2 = 2,3
    # cost2 = [[9,10,11],
    #          [1,2,3]]

    ### End of Test Case

    M1, N1 = 2, 3
    cost1 = [[3, 2, 4],
             [4, 3, 2]]
    
    M2, N2 = 4, 4
    cost2 = [[5, 6, 7, 4],
             [4, 5, 6, 3],
             [6, 4, 5, 2],
             [3, 2, 4, 5]]
    
    M3, N3 = 8, 9
    cost3 = [[90, 100, 60, 5, 50, 1, 100, 80, 70],
             [100, 5, 90, 100, 50, 70, 60, 90, 100],
             [50, 1, 100, 70, 90, 60, 80, 100, 4],
             [60, 100, 1, 80, 70, 90, 100, 50, 100],
             [70, 90, 50, 100, 100, 4, 1, 60, 80],
             [100, 60, 100, 90, 80, 5, 70, 100, 50],
             [100, 4, 80, 100, 90, 70, 50, 1, 60],
             [1, 90, 100, 50, 60, 80, 100, 70, 5]]
    
    M4, N4 = 3, 3
    cost4 = [[2, 5, 6],
             [4, 3, 5],
             [5, 6, 2]]
    
    M5, N5 = 4, 4
    cost5 = [[4, 6, 1, 5],
             [9, 6, 2, 1],
             [6, 5, 3, 9],
             [2, 2, 5, 4]]
    
    M6, N6 = 4, 4
    cost6 = [[5, 4, 6, 7],
             [8, 3, 4, 6],
             [6, 7, 3, 8],
             [7, 8, 9, 2]]
    
    M7, N7 = 4, 4
    cost7 = [[25 * 0.28, 24 * 0.333, 23 * 0.304, 25 * 0.12],
             [25 * 0.32, 24 * 0.25, 23 * 0.087, 25 * 0.24],
             [25 * 0.24, 24 * 0.125, 23 * 0.261, 25 * 0.28],
             [25 * 0.16, 24 * 0.292, 23 * 0.348, 25 * 0.36]]
    
    M8, N8 = 5, 5
    cost8 = [[8, 8, 24, 24, 24],
             [6, 18, 6, 18, 18],
             [30, 10, 30, 10, 30],
             [21, 21, 21, 7, 7],
             [27, 27, 9, 27, 9]]
    
    M9, N9 = 5, 5
    cost9 = [[10, 10, 999, 999, 999],
             [12, 999, 999, 12, 12],
             [999, 15, 15, 999, 999],
             [11, 999, 11, 999, 999],
             [999, 14, 999, 14, 14]]
    
    M10, N10 = 9, 10
    cost10 = [[1, 90, 100, 50, 70, 20, 100, 60, 80, 90],
              [100, 10, 1, 100, 60, 80, 70, 100, 50, 90],
              [90, 50, 70, 1, 100, 100, 60, 90, 80, 100],
              [70, 100, 90, 5, 10, 60, 100, 80, 90, 50],
              [50, 100, 100, 90, 20, 4, 80, 70, 60, 100],
              [100, 5, 80, 70, 90, 100, 4, 50, 1, 60],
              [90, 60, 50, 4, 100, 90, 100, 5, 10, 80],
              [100, 70, 90, 100, 4, 60, 1, 90, 100, 5],
              [80, 100, 5, 60, 50, 90, 70, 100, 4, 1]]

    problems = [(M1, N1, np.array(cost1)),
                (M2, N2, np.array(cost2)),
                (M3, N3, np.array(cost3)),
                (M4, N4, np.array(cost4)),
                (M5, N5, np.array(cost5)),
                (M6, N6, np.array(cost6)),
                (M7, N7, np.array(cost7)),
                (M8, N8, np.array(cost8)),
                (M9, N9, np.array(cost9)),
                (M10, N10, np.array(cost10))]

    # Example for GA execution:
    # TODO: Please set the parameters for the genetic algorithm
    ga = GeneticAlgorithm(
        pop_size=100,
        generations=200,
        mutation_rate=0.02,
        crossover_rate=0.95,
        tournament_size=3,
        elitism=True,
        random_seed=607
    )

    # Solve each problem and immediately write the results to the file
    for i, (M, N, student_times) in enumerate(problems, 1):
        best_allocation, total_time = ga(M=M, N=N, student_times=student_times)
        write_output_to_file(i, total_time)

    print("Results have been written to results.txt")
