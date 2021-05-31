# Beyond Noise: Mitigating the Impact of Fine-grained Semantic Divergences on Neural Machine Translation

This repository contains code for the ACL 2021 paper that can be found [here]()!

## Table of contents

- [Setup](#setup)
- [Documentation](#documentation)
- [Contact](#contact)

1. Create a dedicated virtual environment (here we use [anaconda](https://anaconda.org)) for the project & install requirements:

    ```
    conda create -n semdiv python=3.6
    conda activate semdiv
    conda install --file requirements.txt
    ```

2. Follow setup instructions (i.e.,  install requirements in 1, and complete 2 & 3) of [divergentmBERT repo](https://github.com/Elbria/xling-SemDiv)

3. Run the following script to download and install the required software: 

    ```bash
    bash setup.sh
    ```

## Documentation

**Step 1:** *Download and preprocess WikiMatrix data*
```
bash download-data.sh en fr
```

**Step 2:** *Predict equivalence vs divergences using divergentmBERT trained 
on divergence ranking (process is parallelized to run on 5 GPUs 
using SLURM array jobs on the CLIP cluster)*

```
sbatch --array=0-4 equivalence-vs-divergence-slurm-array-jobs.sh en fr
```

*After the jobs are finished succesfully, extract the equivalence
and divergence*

```sbatch --array=0 equivalence-vs-divergence-slurm-array-jobs.sh en fr extract
```

**Step 3a:** *Prepare divergent data for token-level predictions
(parallelize using SLURM array jobs on the CLIP cluster) within CPU node*
```
bash divergence-for-parallel.sh en fr
```

**Step 3b:** *DivergentmBERT predictions*

```
sbatch  --array=0-4 unrelated-vs-some-difference-slurm-array-jobs.sh en fr
```
```
sbatch  --array=0-4 unrelated-vs-some-difference-slurm-array-jobs.sh en fr extract
```

**Step 4:** *Prepare equivalent data for synthetic divergence generation (augment with word alignment tags, prepare for parallelization) within CPU node*

```
bash equivalence-for-parallel.sh en fr
```

**Step 5:** *Create Subtree deletion divergences*
```
bash r-or-d-divergences.sh en fr d
```

*Create Phrase replacement divergences; Note: avoid parallelization; this process highly depends on how we batchify seeds
in smaller batches the possibility of None replacements or small number of edits
is higher run inside CPU node*

```
bash r-or-d-divergences.sh en fr r
```

**Step 6:** *Create generalization and particularization instances (Lexical Substitution); Note: this process is computationally expensive 
-- parallelization is needed when working at scale (seed >> 1K)
-- performance does not depend on how you batchify (independent instances)*

```
sbatch  --array=0-4 g-or-p-divergences-slurm-array-jobs.sh en fr g
```
```
sbatch  --array=0-4 g-or-p-divergences-slurm-array-jobs.sh en fr p
```

**Step 7:** *Preprocess extracted equivalents vs divergent data*

* 7a) Extracts and preprocesses divergent data beyond noise
```
bash preprocess-remove-unrelated.sh
```

* 7b)
```
bash preprocess-lambda-bicleaner-versions.sh
```

* 7c) Laser baseline
```bash preprocess-laser.sh
```

**Step 8:** *Train NMT*
```
bash nmt-factors-slurm-job.sh
```
## Contact

If you use any contents of this repository, please cite us. For any questions, write to ebriakou@cs.umd.edu.

