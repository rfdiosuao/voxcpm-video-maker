import os, sys, soundfile as sf
sys.path.insert(0, r'd:\VoxCPM\VoxCPM-2.0.3\src')

# 防止 GPU 显存碎片化
os.environ['PYTORCH_CUDA_ALLOC_CONF'] = 'expandable_segments:True'

from voxcpm import VoxCPM
import argparse
import torch

parser = argparse.ArgumentParser()
parser.add_argument('--script-file', required=True)
parser.add_argument('--output-file', required=True)
args = parser.parse_args()

model = VoxCPM(
    voxcpm_model_path=r'd:\VoxCPM\VoxCPM-2.0.3\models\openbmb__VoxCPM2',
    enable_denoiser=False,
    optimize=True,
)

# 清理 GPU 缓存
if torch.cuda.is_available():
    torch.cuda.empty_cache()
    print(f'GPU 显存使用: {torch.cuda.memory_allocated()/1024**3:.2f}GB / {torch.cuda.get_device_properties(0).total_memory/1024**3:.2f}GB')

with open(args.script_file, 'r', encoding='utf-8-sig') as f:
    text = f.read()

print('开始生成配音...')
wav = model.generate(
    text=text,
    reference_wav_path=r'D:\VoxCPM\宇航的克隆素材_wav\第一段.wav',
    cfg_value=2.0,
    inference_timesteps=10,
)

os.makedirs(os.path.dirname(args.output_file), exist_ok=True)
sf.write(args.output_file, wav, model.tts_model.sample_rate)
print(f'配音已保存: {args.output_file}')
