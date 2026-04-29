# Look-up-Based-Cipher

This repository contains SageMath scripts for finding reduced-round collisions in the Reinforced Concrete (RC) permutation. It supports three field instantiations: **BLS381**, **BN254**, and **ST**.



## Dependencies

- **SageMath**

- **Magma**

  

## Source File

Located in the [./RC](.RC)  directory:

\* **`ReinforcedConcrete.sage`**: Implementation of the RC permutation. 

\* **`genPoly.sage`**: Exports the polynomial system for reduced rounds into `.sobj` and `.txt` formats (saved in the `./RC/poly/`).

\* **`GenValidPair.sage`**: Computes the DDT and generates valid input/output differential pairs for target sub-S-boxes (saved in the `./RC/Data/`).

\* **`run_magma_batch.sage`**: Iterates over valid differential trails, dynamically constructs Magma scripts,solves for the variety, and verifies the candidate collisions.

\* **`run.bh`** (or `run_BLS.bh`, `run_BN.bh`, `run_ST.bh`): Bash scripts that submit parallel jobs to Magma across all S-box nodes.



## Workflow

### 1. Generate Equation System

 Run `genPoly.sage` to create the `.sobj` polynomial equations.

```bash
cd ./RC
sage genPoly.sage
```



### 2. Generate Valid Differences

Run `GenValidPair.sage` to build the DDT and filter valid differential trails. The results will be stored in the `./RC/Data/` directory.

```bash
sage GenValidPair.sage
```



### 3. Collision Search

Execute the bash scripts to search for collisions.

```bash
./run_BLS.bh
```

Alternatively, you can run a single instance:

```sage
sage run_magma_batch.sage <cipher.mode_name> <rounds> <index>
# Example: sage run_magma_batch.sage BLS381 2 18
```



Results from the collision search will be stored in the `./RC/collision_result/` directory. 

