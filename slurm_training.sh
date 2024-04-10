#!/bin/bash
#SBATCH --job-name=train_mtr
#SBATCH --output=/home/slurm/shared_folder/erik/mtr_training_%j.txt
#SBATCH --ntasks=1
#SBATCH --mem=128G
#SBATCH -D /home/slurm
#SBATCH --gres=gpu:rtx4090:4

# Set up a variable for the virtual environment directory
VENV_DIR="/home/slurm/venvs/mtr_pose"

# Activate the virtual environment
source $VENV_DIR/bin/activate

# Optionally, run a Python script using this virtual environment
# python my_script.py

set -x

while true
do
    PORT=$(( ((RANDOM<<15)|RANDOM) % 49152 + 10000 ))
    status="$(nc -z 127.0.0.1 $PORT < /dev/null &>/dev/null; echo $?)"
    if [ "${status}" != "0" ]; then
        break;
    fi
done
echo $PORT

cd /home/slurm/shared_folder/erik/MTR/tools

torchrun --nproc_per_node=4 --rdzv_endpoint=localhost:${PORT} train.py --launcher slurm --cfg_file /home/slurm/shared_folder/erik/MTR/tools/cfgs/waymo/mtr+100_percent_data.yaml --batch_size=8 --epochs=120 --extra_tag=MTR_wo_poses --tcp_port=$PORT

# Deactivate the virtual environment at the end
deactivate